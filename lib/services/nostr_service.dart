import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/services/connectivity_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:logger/logger.dart';
import 'package:ndk/ndk.dart' hide Logger; // Hide conflicting Logger from NDK
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:signals/signals_flutter.dart';

class NostrService {
  // Singleton pattern.
  factory NostrService() {
    return _instance;
  }

  NostrService._internal();

  static final NostrService _instance = NostrService._internal();

  // Initialize FlutterSecureStorage for npub/nsec.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  Ndk? _ndkInstance;

  // Getter for Ndk with lazy initialization.
  Ndk get _ndk {
    _ndkInstance ??= Ndk(
        NdkConfig(
          bootstrapRelays: _defaultRelays,
          cache: MemCacheManager(),
          eventVerifier: Bip340EventVerifier(),
          // Reduce default query timeout to avoid long hangs on slow relays.
          defaultQueryTimeout: const Duration(seconds: 5),
        ),
      );
    return _ndkInstance!;
  }

  // Custom Kind for GYMPLY workout posts. This number was chosen randomly,
  // now GYMPLY sticks with it.
  static const int kGymplyWorkoutKind = 6742;

  // Static list of 8 reliable Nostr relays.
  final List<String> _defaultRelays = <String>[
    'wss://relay.primal.net',
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.snort.social',
    'wss://relay.nostr.band',
    'wss://relay.nostr.wine',
    'wss://nostr.mom',
    'wss://atlas.nostr.land',
  ];

  // Static list of 5 Blossom servers for image hosting.
  final List<String> _defaultBlossomServers = <String>[
    'https://blossom.primal.net',
    'https://nostr.checkreels.com',
    'https://nostr.download',
    'https://cdn.nostr.build',
    'https://blossom.nostr.v0l.io',
  ];

  // --- SIGNALS ---

  // String Signal to track npub.
  final Signal<String?> sNpub = Signal<String?>(null, debugLabel: 'sNpub');
  // ONLY track if nsec is available, this is a SECRET, DO NOT TRACK.
  final Signal<bool> sNsec = Signal<bool>(false, debugLabel: 'sNsec');

  // Metadata Signal for own profile metadata.
  final Signal<Metadata?> sMetadata = Signal<Metadata?>(
    null,
    debugLabel: 'sMetadata',
  );

  // Signal<List<Nip01Event>> for Feed Events.
  final Signal<List<Nip01Event>> sFeedEvents = Signal<List<Nip01Event>>(
    <Nip01Event>[],
    debugLabel: 'sFeedEvents',
  );

  // Signal for Metadata Map (pubkey -> Metadata).
  final Signal<Map<String, Metadata>> sFeedMetadata =
      Signal<Map<String, Metadata>>(
        <String, Metadata>{},
        debugLabel: 'sFeedMetadata',
      );

  // Signal for Comments of the currently opened WorkoutNote.
  final Signal<List<Nip01Event>> sActiveWorkoutComments =
      Signal<List<Nip01Event>>(
        <Nip01Event>[],
        debugLabel: 'sActiveWorkoutComments',
      );

  // Signal to keep track of reactions to every WorkoutNote on screen.
  final Signal<Map<String, Set<String>>> sFeedReactions =
      Signal<Map<String, Set<String>>>(
        <String, Set<String>>{},
        debugLabel: 'sFeedReactions',
      );

  // Signal to keep track of comments to every WorkoutNote on screen.
  final Signal<Map<String, Set<String>>> sFeedComments =
      Signal<Map<String, Set<String>>>(
        <String, Set<String>>{},
        debugLabel: 'sFeedComments',
      );

  // Bool Signal to track feed loading state.
  final Signal<bool> sLoadingFeed = Signal<bool>(
    false,
    debugLabel: 'sLoadingFeed',
  );

  // --- SUBSCRIPTIONS ---

  StreamSubscription<Nip01Event>? _feedSubscription;
  StreamSubscription<Nip01Event>? _reactionSubscription;
  StreamSubscription<Nip01Event>? _commentSubscription;
  Timer? _engagementDebounce;

  // --- METHODS ---

  // Initialize Nostr service (ndk package).
  Future<void> init() async {
    // Set npub/nsec Signals from FlutterSecureStorage.
    final String? npub = await _storage.read(key: 'nostr_npub');
    final String? nsec = await _storage.read(key: 'nostr_nsec');

    // Set Signals, keep nsec SECRET.
    sNpub.value = npub;
    sNsec.value = nsec != null;

    // Reactive effect to handle login/metadata when online.
    effect(() async {
      final bool online = sIsOnline.value;
      final String? currentNpub = sNpub.value;

      // Only initialize NDK if we have an account and are online.
      if (online && currentNpub != null) {
        final String pubkeyHex = Nip19.decode(currentNpub);

        // Only login if NDK doesn't have the account yet.
        if (_ndkInstance == null || !_ndk.accounts.hasAccount(pubkeyHex)) {
          final String? currentNsec = await getNsec();
          await _loginToNdk(currentNpub, currentNsec);
          _logger.i('NostrService: Logged in reactively (Online: $online)');
        }

        // Fetch metadata silently in background.
        if (sMetadata.value == null) {
          await fetchMetadata(silent: true);
        }
      }
    });

    _logger.i('NostrService: Initialized (Keys: ${npub != null})');
  }

  // Login to Nostr with npub/nsec.
  Future<void> _loginToNdk(String npub, String? nsec) async {
    final String pubkeyHex = Nip19.decode(npub);

    // If npub already exists in NDK, remove it first.
    // Fixes 'npub already present'.
    if (_ndk.accounts.hasAccount(pubkeyHex)) {
      _ndk.accounts.removeAccount(pubkey: pubkeyHex);
    }

    if (nsec != null) {
      // Login with nsec.
      final String privkeyHex = Nip19.decode(nsec);
      _ndk.accounts.loginPrivateKey(pubkey: pubkeyHex, privkey: privkeyHex);
    } else {
      // Login with npub.
      _ndk.accounts.loginPublicKey(pubkey: pubkeyHex);
    }
  }

  // Load profile for a specific pubkey (hex or npub).
  Future<Metadata?> getMetadataForPubkey(
    String pubkey, {
    bool silent = false,
  }) async {
    final String hex = pubkey.startsWith('npub')
        ? Nip19.decode(pubkey)
        : pubkey;
    try {
      // Load metadata from NDK with a timeout to prevent hanging.
      return await _ndk.metadata
          .loadMetadata(hex)
          .timeout(
            const Duration(seconds: 5),
          );
    } on Object catch (e) {
      // Log error.
      _logger.w('Failed to load metadata for $pubkey: $e');

      // Show toast to user if not silent.
      if (!silent) {
        ToastService.showError(title: 'Error Loading Metadata', subtitle: '$e');
      }

      return null;
    }
  }

  // Load OWN metadata.
  Future<void> fetchMetadata({bool silent = false}) async {
    if (sNpub.value == null) return;

    // Use npub to load metadata.
    final Metadata? meta = await getMetadataForPubkey(
      sNpub.value!,
      silent: silent,
    );
    if (meta != null) {
      // Set Signal with fetched metadata.
      sMetadata.value = meta;

      // Log success.
      _logger.i('Metadata fetched successfully: $meta');
    }
  }

  // Publish WorkoutNote using Waterfall Strategy (polite to Nostr servers).
  Future<void> publishWorkoutNote({required Uint8List imageBytes}) async {
    if (!sNsec.value) throw Exception('No Private Key found.');

    // Prepare Waterfall List: blossom.primal.net first, then others shuffled.
    final List<String> fallbacks = List<String>.from(_defaultBlossomServers)
      ..remove('https://blossom.primal.net')
      ..shuffle();
    final List<String> waterfallServers = <String>[
      'https://blossom.primal.net',
      ...fallbacks,
    ];

    BlobUploadResult? success;

    // Iterate through servers one by one until one succeeds.
    for (final String serverUrl in waterfallServers) {
      try {
        final List<BlobUploadResult> results = await _ndk.blossom.uploadBlob(
          data: imageBytes,
          serverUrls: <String>[serverUrl],
          contentType: 'image/png',
        );

        if (results.isNotEmpty &&
            results.first.success &&
            results.first.descriptor != null) {
          success = results.first;
          break;
        }
      } on Object catch (e) {
        // Log warning (this is NOT an error!).
        _logger.w('Upload failed for $serverUrl: $e');
      }
    }

    // If none of servers returns success, operation fails.
    if (success == null) {
      // Log error (NOW it's an error).
      _logger.e('Image upload failed across all servers.');

      // Show toast to user.
      ToastService.showError(
        title: 'Image Upload Failed',
        subtitle: 'None of the Nostr Blossom servers accepted the upload.',
      );

      // Throw.
      throw Exception('Image upload failed.');
    }

    final String imageUrl = success.descriptor!.url;

    // Log which server was used.
    _logger.i('Image uploaded successfully to: $imageUrl');

    // Create Nip01Event. Specifically use kGymplyWorkoutKind, and GYMPLY tags.
    final Nip01Event event = Nip01Event(
      pubKey: Nip19.decode(sNpub.value!),
      kind: kGymplyWorkoutKind,
      content: jsonEncode(<String, dynamic>{
        'image': imageUrl,
        'app': 'GYMPLY.',
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: <List<String>>[
        <String>['t', 'gymply'],
      ],
    );

    // Broadcast event to relays.
    unawaited(
      _ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture.then((_) {
        // Log success.
        _logger.i('Workout post broadcast confirmed by relays.');

        // Show toast to user.
        ToastService.showSuccess(
          title: 'Workout Note Broadcasted',
          subtitle: 'Added Workout Note to GYMPLY. feed',
        );
      }),
    );

    // Instant UI injection (no need to refresh feed).
    final List<Nip01Event> newList = <Nip01Event>[event, ...sFeedEvents.value]
      ..sort(
        (Nip01Event a, Nip01Event b) {
          return b.createdAt.compareTo(a.createdAt);
        },
      );
    sFeedEvents.value = newList;
  }

  // Publish a Comment (Kind 1).
  Future<void> sendComment({
    required String content,
    required String rootId,
    required String rootAuthorPubKey,
    String? replyToId,
    String? replyToPubKey,
  }) async {
    if (!sNsec.value) throw Exception('No Private Key found.');

    final Nip01Event event = Nip01Event(
      pubKey: Nip19.decode(sNpub.value!),
      kind: 1,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: <List<String>>[
        <String>['e', rootId, '', 'root'],
        <String>['p', rootAuthorPubKey],
        if (replyToId != null) <String>['e', replyToId, '', 'reply'],
        if (replyToPubKey != null) <String>['p', replyToPubKey],
        <String>['t', 'gymply'],
      ],
    );

    // --- OPTIMISTIC UI UPDATES ---

    // 1. Update Active Modal List.
    if (!sActiveWorkoutComments.value.any((Nip01Event e) => e.id == event.id)) {
      final List<Nip01Event> newList =
          <Nip01Event>[...sActiveWorkoutComments.value, event]..sort(
            (Nip01Event a, Nip01Event b) => a.createdAt.compareTo(b.createdAt),
          );
      sActiveWorkoutComments.value = newList;
    }

    // 2. Update Feed Counter.
    final Map<String, Set<String>> currentComments = sFeedComments.value;
    final Set<String> eventComments = Set<String>.from(
      currentComments[rootId] ?? <String>{},
    );

    if (eventComments.add(event.id)) {
      final Map<String, Set<String>> newMap = Map<String, Set<String>>.from(
        currentComments,
      );
      newMap[rootId] = eventComments;
      sFeedComments.value = newMap;
    }

    // --- BROADCAST ---

    try {
      await _ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;

      // Fetch metadata for the commenter (me).
      await _resolveMetadata(event.pubKey);

      _logger.i('Comment broadcasted successfully');
    } on Object catch (e) {
      _logger.e('Failed to send comment: $e');
      ToastService.showError(title: 'Comment Failed', subtitle: '$e');
    }
  }

  // Delete a Comment.
  Future<void> deleteComment(String commentId, String workoutId) async {
    if (!sNsec.value) return;

    // --- OPTIMISTIC UI UPDATES ---

    // 1. Remove from Modal List.
    final List<Nip01Event> modalComments = List<Nip01Event>.from(
      sActiveWorkoutComments.value,
    )..removeWhere((Nip01Event e) => e.id == commentId);
    sActiveWorkoutComments.value = modalComments;

    // 2. Decrement Feed Counter.
    final Map<String, Set<String>> currentComments = sFeedComments.value;
    if (currentComments.containsKey(workoutId)) {
      final Set<String> eventComments = Set<String>.from(
        currentComments[workoutId]!,
      );
      if (eventComments.remove(commentId)) {
        final Map<String, Set<String>> newMap = Map<String, Set<String>>.from(
          currentComments,
        );
        if (eventComments.isEmpty) {
          newMap.remove(workoutId);
        } else {
          newMap[workoutId] = eventComments;
        }
        sFeedComments.value = newMap;
      }
    }

    // --- BROADCAST DELETION (Kind 5) ---

    final Nip01Event deletionEvent = Nip01Event(
      pubKey: Nip19.decode(sNpub.value!),
      kind: 5,
      content: 'Comment deleted in GYMPLY.',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: <List<String>>[
        <String>['e', commentId],
        <String>['k', '1'],
      ],
    );

    try {
      await _ndk.broadcast
          .broadcast(nostrEvent: deletionEvent)
          .broadcastDoneFuture;
      _logger.i('Comment deletion broadcasted');
    } on Object catch (e) {
      _logger.e('Failed to delete comment: $e');
    }
  }

  // Sends 'Like' (Kind 7) to WorkoutNote or Comment.
  Future<void> sendBicepsReaction(String eventId, {String? rootId}) async {
    if (!sNsec.value) return;

    final String myPubkey = Nip19.decode(sNpub.value!);

    // Optimistic UI update: Add 'like' immediately.
    final Map<String, Set<String>> reactions = Map<String, Set<String>>.from(
      sFeedReactions.value,
    );
    final Set<String> eventLikes = Set<String>.from(
      reactions[eventId] ?? <String>{},
    );

    // Return if already liked.
    if (eventLikes.contains(myPubkey)) return;

    eventLikes.add(myPubkey);
    reactions[eventId] = eventLikes;
    sFeedReactions.value = reactions;

    // Create Kind 7 'Like' event.
    final Nip01Event event = Nip01Event(
      pubKey: myPubkey,
      kind: 7,
      content: '💪',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: <List<String>>[
        <String>['e', eventId],
        <String>['p', myPubkey],
        if (rootId != null && rootId != eventId)
          <String>['e', rootId, '', 'root'],
      ],
    );

    // Broadcast to relays.
    try {
      await _ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;

      // Log success.
      _logger.i("'Like' Reaction broadcasted for event: $eventId");
    } on Object catch (e) {
      // Log error.
      _logger.e('Failed to send reaction: $e');

      // Show toast to user.
      ToastService.showError(
        title: "Reaction 'Like' Failed",
        subtitle: '$e',
      );
    }
  }

  // Delete WorkoutNote by sending Kind 5 (Event Deletion) event.
  Future<void> deleteWorkoutNote(String eventId) async {
    // Only users with a private key (nsec) can delete their own events.
    if (!sNsec.value) return;

    // Optimistic UI update: Remove from sFeedEvents signal immediately.
    final List<Nip01Event> events = List<Nip01Event>.from(sFeedEvents.value)
      ..removeWhere((Nip01Event e) {
        return e.id == eventId;
      });
    sFeedEvents.value = events;

    // Refresh reaction subscription to exclude the deleted event.
    _updateEngagementSubscription();

    // Create Kind 5 deletion event.
    final Nip01Event deletionEvent = Nip01Event(
      pubKey: Nip19.decode(sNpub.value!),
      kind: 5,
      content: 'Deleted by user in GYMPLY.',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: <List<String>>[
        <String>['e', eventId],
        <String>['k', '$kGymplyWorkoutKind'],
      ],
    );

    // Broadcast to relays.
    try {
      await _ndk.broadcast
          .broadcast(nostrEvent: deletionEvent)
          .broadcastDoneFuture;

      // Log success.
      _logger.i('Deletion request (Kind 5) broadcasted for event: $eventId');

      // Show toast to user.
      ToastService.showSuccess(
        title: 'Deletion Requested',
        subtitle: 'Nostr deletion event created',
      );
    } on Object catch (e) {
      // Log error.
      _logger.e('Failed to broadcast deletion request: $e');

      // Show toast to user.
      ToastService.showError(
        title: 'Deletion Request Failed',
        subtitle: '$e',
      );
    }
  }

  // --- FEED LOGIC ---

  // Set up Nostr subscription for GYMPLY workout events.
  void startFeedSubscriptions() {
    // Prevent multiple simultaneous subscriptions.
    if (_feedSubscription != null) return;

    // Don't start if offline.
    if (!sIsOnline.value) return;

    // Set Signal.
    sLoadingFeed.value = true;

    // Request a subscription for Kind 6742 (GYMPLY Workouts): 50 events max.
    _feedSubscription = _ndk.requests
        .subscription(
          name: 'gymply-global-feed',
          filter: Filter(kinds: <int>[kGymplyWorkoutKind], limit: 50),
        )
        .stream
        .listen((Nip01Event event) async {
          // Duplicate Check: Process only unique IDs.
          if (!sFeedEvents.value.any((Nip01Event e) {
            return e.id == event.id;
          })) {
            // Update Feed List (newest first).
            final List<Nip01Event> newList =
                <Nip01Event>[event, ...sFeedEvents.value]..sort(
                  (Nip01Event a, Nip01Event b) {
                    return b.createdAt.compareTo(a.createdAt);
                  },
                );
            // Set Signal.
            sFeedEvents.value = newList;

            // Fetch user's name/avatar and refresh listeners.
            await _resolveMetadata(event.pubKey);

            // Debounce the engagement subscription update.
            _engagementDebounce?.cancel();
            _engagementDebounce = Timer(
              const Duration(seconds: 2),
              _updateEngagementSubscription,
            );
          }

          // Loading State Cleanup.
          if (sLoadingFeed.value && sFeedEvents.value.isNotEmpty) {
            sLoadingFeed.value = false;
          }
        });

    // If no events are found after 5 seconds, stop the spinner.
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (sLoadingFeed.value) {
        sLoadingFeed.value = false;
      }
    });
  }

  // Update subscription for reactions and comments to match currently
  // visible posts.
  void _updateEngagementSubscription() {
    // Cancel previous subscription to prevent duplicate listeners.
    unawaited(_reactionSubscription?.cancel());

    // Gather IDs of all WorkoutNotes currently in our feed signal.
    final List<String> eventIds = sFeedEvents.value.map((Nip01Event e) {
      return e.id;
    }).toList();

    // No posts, no subscription.
    if (eventIds.isEmpty) return;

    // Request subscription for Kind 7 (Reactions) and Kind 1 (Comments)
    // filtered by event IDs.
    _reactionSubscription = _ndk.requests
        .subscription(
          name: 'gymply-engagement',
          filter: Filter(kinds: <int>[1, 7], eTags: eventIds),
        )
        .stream
        .listen((Nip01Event event) {
          // Find 'e' tag to id which WorkoutNote this event belongs to.
          final List<String> eTag = event.tags.firstWhere(
            (List<String> t) {
              return t.length >= 2 && t[0] == 'e';
            },
            orElse: () {
              return <String>[];
            },
          );

          if (eTag.isEmpty) return;
          final String targetEventId = eTag[1];

          // Handle Reactions (Kind 7).
          if (event.kind == 7 && event.content == '💪') {
            final Map<String, Set<String>> reactions =
                Map<String, Set<String>>.from(sFeedReactions.value);
            final Set<String> eventLikes = Set<String>.from(
              reactions[targetEventId] ?? <String>{},
            )..add(event.pubKey);

            reactions[targetEventId] = eventLikes;
            sFeedReactions.value = reactions;

            // Fetch metadata for the person who liked.
            unawaited(_resolveMetadata(event.pubKey));
          }
          // Handle Comments (Kind 1).
          else if (event.kind == 1) {
            final Map<String, Set<String>> currentComments =
                sFeedComments.value;
            final Set<String> eventComments = Set<String>.from(
              currentComments[targetEventId] ?? <String>{},
            );

            if (eventComments.add(event.id)) {
              final Map<String, Set<String>> newMap =
                  Map<String, Set<String>>.from(currentComments);
              newMap[targetEventId] = eventComments;
              sFeedComments.value = newMap;
            }
          }
        });
  }

  // Subscribe to comments for a specific post.
  void startCommentSubscription(String eventId) {
    unawaited(_commentSubscription?.cancel());
    sActiveWorkoutComments.value = <Nip01Event>[];

    _commentSubscription = _ndk.requests
        .subscription(
          name: 'gymply-comments-$eventId',
          filter: Filter(kinds: <int>[1, 7], eTags: <String>[eventId]),
        )
        .stream
        .listen((Nip01Event event) async {
          // Handle Comments (Kind 1).
          if (event.kind == 1) {
            if (!sActiveWorkoutComments.value.any(
              (Nip01Event e) => e.id == event.id,
            )) {
              final List<Nip01Event> newList =
                  <Nip01Event>[...sActiveWorkoutComments.value, event]..sort(
                    (Nip01Event a, Nip01Event b) =>
                        a.createdAt.compareTo(b.createdAt),
                  );
              sActiveWorkoutComments.value = newList;
              await _resolveMetadata(event.pubKey);
            }
          }
          // Handle Reactions (Kind 7) to comments.
          else if (event.kind == 7 && event.content == '💪') {
            final List<String> eTag = event.tags.firstWhere(
              (List<String> t) => t.length >= 2 && t[0] == 'e',
              orElse: () => <String>[],
            );

            if (eTag.isNotEmpty) {
              final String targetId = eTag[1];
              final Map<String, Set<String>> reactions =
                  Map<String, Set<String>>.from(sFeedReactions.value);
              final Set<String> eventLikes = Set<String>.from(
                reactions[targetId] ?? <String>{},
              )..add(event.pubKey);

              if (reactions[targetId]?.length != eventLikes.length) {
                reactions[targetId] = eventLikes;
                sFeedReactions.value = reactions;
              }
            }
          }
        });
  }

  void stopCommentSubscription() {
    unawaited(_commentSubscription?.cancel());
    _commentSubscription = null;
    sActiveWorkoutComments.value = <Nip01Event>[];
  }

  // Fetch Nostr profile data for a specific user and cache it.
  Future<void> _resolveMetadata(String pubkey) async {
    // User's metadata already present, skip fetch.
    if (sFeedMetadata.value.containsKey(pubkey)) return;

    try {
      // Load profile (Name, Avatar, etc.) from NDK.
      // Resolve SILENTLY as this is background activity.
      final Metadata? meta = await getMetadataForPubkey(pubkey, silent: true);

      if (meta != null) {
        // Set Signal from new Map to trigger UI change.
        final Map<String, Metadata> newMap = Map<String, Metadata>.from(
          sFeedMetadata.value,
        );
        newMap[pubkey] = meta;
        sFeedMetadata.value = newMap;

        // Log success.
        _logger.i('Metadata resolved for $pubkey');
      }
    } on Object catch (e) {
      // Log error.
      _logger.e('Could not resolve metadata for $pubkey: $e');

      // Show toast to user.
      ToastService.showError(
        title: 'Error Resolving Metadata',
        subtitle: '$e',
      );
    }
  }

  // Kill subscriptions.
  Future<void> stopFeedSubscriptions() async {
    _engagementDebounce?.cancel();
    await _feedSubscription?.cancel();
    await _reactionSubscription?.cancel();
    _feedSubscription = null;
    _reactionSubscription = null;
  }

  // Refresh Feed.
  Future<void> refreshFeed() async {
    sFeedEvents.value = <Nip01Event>[];
    sFeedReactions.value = <String, Set<String>>{};
    sFeedComments.value = <String, Set<String>>{};
    await stopFeedSubscriptions();
    startFeedSubscriptions();
  }

  // --- OTHERS ---

  // Publishe NIP-65 Relay List (Kind 10002).
  // This tells other Nostr clients where to find GYMPLY posts and where to
  // send messages (replies/likes).
  Future<void> publishRelayList() async {
    // Only users with an nsec (private key) can sign and publish their
    // relay list.
    if (!sNsec.value) return;

    final String myPubkey = Nip19.decode(sNpub.value!);

    // Construct the NIP-65 tags.
    // Standard format: ['r', 'wss://relay.url', 'read'|'write' (optional)].
    // By omitting the 3rd parameter, we signal that these relays are for BOTH.
    final List<List<String>> tags = _defaultRelays.map((String url) {
      return <String>['r', url];
    }).toList();

    final Nip01Event relayListEvent = Nip01Event(
      pubKey: myPubkey,
      kind: 10002,
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: tags,
    );

    try {
      // Use NDK broadcast. This is polite to the network as it handles
      // relay-specific failures in the background.
      await _ndk.broadcast
          .broadcast(nostrEvent: relayListEvent)
          .broadcastDoneFuture;
      _logger.i('NIP-65 Relay list successfully published to the network.');
    } on Object catch (e) {
      // We log this as a warning but don't interrupt the user, as the app
      // will still function using bootstrap defaults.
      _logger.w('Relay list publication deferred: $e');
    }
  }

  Future<void> updateMetadata(Metadata metadata) async {
    // Illegal action.
    if (sNpub.value == null) return;

    // Broadcast metadata update.
    final Metadata updated = await _ndk.metadata.broadcastMetadata(metadata);

    // Best Practice: Also broadcast relay list (NIP-65) whenever profile is
    // updated to ensure global discoverability.
    unawaited(publishRelayList());

    // Set Signal.
    sMetadata.value = updated;

    // Log success.
    _logger.i('Metadata updated successfully');

    // Show toast to user.
    ToastService.showSuccess(
      title: 'Metadata Updated',
      subtitle: 'Your profile has been updated',
    );
  }

  // Create NEW Nostr user.
  Future<bool> generateKeys() async {
    try {
      // Create new key pair (npub & nsec).
      final KeyPair keyPair = Bip340.generatePrivateKey();

      // Write to FlutterSecureStorage.
      await _storage.write(key: 'nostr_npub', value: keyPair.publicKeyBech32);
      await _storage.write(key: 'nostr_nsec', value: keyPair.privateKeyBech32);

      // Set Signals.
      sNpub.value = keyPair.publicKeyBech32;
      sNsec.value = true;

      // Login to NDK with new keys.
      await _loginToNdk(sNpub.value!, keyPair.privateKeyBech32);

      // Fetch OWN metadata.
      await fetchMetadata();

      // One-time relay list publication for new users.
      unawaited(publishRelayList());

      // Log success.
      _logger.i('Keys generated successfully');

      // Show toast to user.
      ToastService.showSuccess(
        title: 'Keys Generated',
        subtitle: 'You now have complete access to Nostr',
      );

      return true;
    } on Object catch (e) {
      // Log error.
      _logger.e('Error generating keys: $e');

      // Show toast to user.
      ToastService.showError(
        title: 'Error Generating Keys',
        subtitle: '$e',
      );

      return false;
    }
  }

  // Import existing Nostr user.
  Future<bool> useExistingKeys(String input) async {
    final String cleanInput = input.trim();

    try {
      // User input is nsec.
      if (Nip19.isPrivateKey(cleanInput)) {
        final String privHex = Nip19.decode(cleanInput);
        final String pubHex = Bip340.getPublicKey(privHex);
        final String npub = Nip19.encodePubKey(pubHex);

        // Store in FlutterSecureStorage.
        await _storage.write(key: 'nostr_npub', value: npub);
        await _storage.write(key: 'nostr_nsec', value: cleanInput);

        // Set Signals.
        sNpub.value = npub;
        sNsec.value = true;
      }
      // User input is npub.
      else if (Nip19.isPubkey(cleanInput)) {
        // Store in FlutterSecureStorage.
        await _storage.write(key: 'nostr_npub', value: cleanInput);
        await _storage.delete(key: 'nostr_nsec');

        // Set Signals.
        sNpub.value = cleanInput;
        sNsec.value = false;
      } else {
        return false;
      }

      // Login to NDK.
      await _loginToNdk(sNpub.value!, sNsec.value ? cleanInput : null);

      // Fetch OWN metadata.
      await fetchMetadata();

      // One-time relay list publication for new users.
      unawaited(publishRelayList());

      // Log success.
      _logger.i('Keys imported successfully');

      // Show toast to user.
      ToastService.showSuccess(
        title: 'Keys Imported',
        subtitle: 'You now have complete access to Nostr',
      );

      return true;
    } on Object catch (e) {
      // Log error.
      _logger.e('Error using existing keys: $e');

      // Show toast to user.
      ToastService.showError(
        title: 'Error Importing Keys',
        subtitle: '$e',
      );

      return false;
    }
  }

  // Delete keys from device (removes Feed tab).
  Future<void> logout() async {
    // Delete keys from FlutterSecureStorage.
    await _storage.delete(key: 'nostr_npub');
    await _storage.delete(key: 'nostr_nsec');

    // Logout from NDK.
    _ndk.accounts.logout();

    // Set Signals.
    sNpub.value = null;
    sNsec.value = false;
    sMetadata.value = null;
    sFeedEvents.value = <Nip01Event>[];
    sFeedMetadata.value = <String, Metadata>{};
    sFeedReactions.value = <String, Set<String>>{};
    sFeedComments.value = <String, Set<String>>{};

    // Kill subscriptions.
    await stopFeedSubscriptions();
  }

  // Get nsec from secure storage.
  Future<String?> getNsec() async {
    return _storage.read(key: 'nostr_nsec');
  }
}

// Globalize NostrService.
final NostrService nostrService = NostrService();
