import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:logger/logger.dart';
import 'package:ndk/ndk.dart' hide Logger; // Hide conflicting Logger from NDK
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:signals/signals_flutter.dart';

class NostrService {
  // Initialize FlutterSecureStorage for npub/nsec.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  late Ndk _ndk;

  // Custom Kind for GYMPLY workout posts.
  static const int kGymplyWorkoutKind = 6742;

  // Static list of 7 reliable Nostr relays.
  final List<String> _defaultRelays = <String>[
    'wss://relay.primal.net',
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.snort.social',
    'wss://offchain.pub',
    'wss://nostr.mom',
    'wss://nostr.bitcoiner.social',
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

  // Track keys.
  final Signal<String?> sNpub = Signal<String?>(null, debugLabel: 'sNpub');
  final Signal<bool> sNsec = Signal<bool>(false, debugLabel: 'sNsec');

  // Signal for own profile metadata.
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

  // Signal to keep track of reactions to every WorkoutNote on screen.
  final Signal<Map<String, Set<String>>> sFeedReactions =
      Signal<Map<String, Set<String>>>(
        <String, Set<String>>{},
        debugLabel: 'sFeedReactions',
      );

  // Signal for loading state.
  final Signal<bool> sLoadingFeed = Signal<bool>(
    false,
    debugLabel: 'sLoadingFeed',
  );

  // --- SUBSCRIPTIONS ---

  StreamSubscription<Nip01Event>? _feedSubscription;
  StreamSubscription<Nip01Event>? _reactionSubscription;

  // --- METHODS ---

  // Initialize Nostr service (ndk package).
  Future<void> init() async {
    _ndk = Ndk(
      NdkConfig(
        bootstrapRelays: _defaultRelays,
        cache: MemCacheManager(),
        eventVerifier: Bip340EventVerifier(),
      ),
    );

    // Set npub/nsec Signals from FlutterSecureStorage.
    final String? npub = await _storage.read(key: 'nostr_npub');
    final String? nsec = await _storage.read(key: 'nostr_nsec');
    sNpub.value = npub;
    sNsec.value = nsec != null;

    if (npub != null) {
      // Login to Nostr.
      await _loginToNdk(npub, nsec);

      // Fetch MetaData.
      await fetchMetadata();

      // Log success.
      _logger.i('Nostr service initialized successfully for $npub');
    }
  }

  // Login to Nostr with npub/nsec.
  Future<void> _loginToNdk(String npub, String? nsec) async {
    final String pubkeyHex = Nip19.decode(npub);

    // If npub already exists in NDK, remove it first.
    // Fixes 'npub already present,
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
  Future<Metadata?> getMetadataForPubkey(String pubkey) async {
    final String hex = pubkey.startsWith('npub')
        ? Nip19.decode(pubkey)
        : pubkey;
    try {
      // Load metadata from NDK.
      return await _ndk.metadata.loadMetadata(hex);
    } on Object catch (e) {
      // Log error.
      _logger.w('Failed to load metadata for $pubkey: $e');
      return null;
    }
  }

  // Load OWN metadata.
  Future<void> fetchMetadata() async {
    if (sNpub.value == null) return;

    // Use npub to load metadata.
    final Metadata? meta = await getMetadataForPubkey(sNpub.value!);
    if (meta != null) {
      // Set Signal with fetched metadata.
      sMetadata.value = meta;

      // Log success.
      _logger.i('Metadata fetched successfully');
    }
  }

  // Publish workout image.
  Future<void> publishWorkoutNote({required Uint8List imageBytes}) async {
    if (!sNsec.value) throw Exception('No Private Key found.');

    // Upload image to 5 Blossom servers simultaneously.
    final List<BlobUploadResult> uploadResults = await _ndk.blossom.uploadBlob(
      data: imageBytes,
      serverUrls: _defaultBlossomServers,
      contentType: 'image/png',
    );

    // Find the first successful upload => descriptor is returned (URL).
    final BlobUploadResult? success = uploadResults
        .cast<BlobUploadResult?>()
        .firstWhere(
          (BlobUploadResult? r) {
            return r != null && r.success && r.descriptor != null;
          },
          orElse: () {
            return null;
          },
        );

    // If none of servers returns success, operation fails.
    if (success == null) {
      // Log error.
      _logger.e('Image upload failed.');

      // Show toast to user.
      ToastService.showError(
        title: 'Image Upload Failed',
        subtitle: 'None of the servers returned success.',
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

  /// Sends 'Like' (Kind 7) with Biceps emoji.
  Future<void> sendBicepsReaction(String eventId) async {
    if (!sNsec.value) return;

    final String myPubkey = Nip19.decode(sNpub.value!);

    // Optimistic UI update: Add 'like' immediately.
    // ignore: always_specify_types
    final Map<String, Set<String>> reactions = Map.from(sFeedReactions.value);
    //
    // ignore: always_specify_types
    final Set<String> eventLikes = Set.from(reactions[eventId] ?? <String>{});

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
        <String>[
          'p',
          Nip19.decode(sNpub.value!),
        ],
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
    _updateReactionSubscription();

    // Create Kind 5 deletion event.
    final Nip01Event deletionEvent = Nip01Event(
      pubKey: Nip19.decode(sNpub.value!),
      kind: 5,
      content: 'Deleted by user in GYMPLY.',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: <List<String>>[
        <String>['e', eventId],
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
          if (!sFeedEvents.value.any((Nip01Event e) => e.id == event.id)) {
            // Update Feed List (newest first).
            final List<Nip01Event> newList =
                <Nip01Event>[event, ...sFeedEvents.value]..sort(
                  (Nip01Event a, Nip01Event b) =>
                      b.createdAt.compareTo(a.createdAt),
                );
            // Set Signal.
            sFeedEvents.value = newList;

            // Fetch user's name/avatar and refresh our reaction listeners.
            await _resolveMetadata(event.pubKey);
            _updateReactionSubscription();
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

  // Update subscription for reactions to match currently visible posts.
  void _updateReactionSubscription() {
    // Cancel previous subscription to prevent duplicate listeners.
    unawaited(_reactionSubscription?.cancel());

    // Gather IDs of all WorkoutNotes currently in our feed signal.
    final List<String> eventIds = sFeedEvents.value.map((Nip01Event e) {
      return e.id;
    }).toList();

    // No posts, no subscription.
    if (eventIds.isEmpty) return;

    // Request subscription for Kind 7 (Reactions) filtered by event IDs.
    _reactionSubscription = _ndk.requests
        .subscription(
          name: 'gymply-reactions',
          filter: Filter(kinds: <int>[7], eTags: eventIds),
        )
        .stream
        .listen((Nip01Event reaction) {
          // Find 'e' tag to id which WorkoutNote this reaction belongs to.
          final List<String> eTag = reaction.tags.firstWhere(
            (List<String> t) {
              return t.length >= 2 && t[0] == 'e';
            },
            orElse: () {
              return <String>[];
            },
          );

          // Only track biceps emoji for this feed.
          if (eTag.isNotEmpty && reaction.content == '💪') {
            final String targetEventId = eTag[1];

            // Set Signal using Set to ensure unique likers per WorkoutNote.
            final Map<String, Set<String>> reactions =
                Map<String, Set<String>>.from(sFeedReactions.value);
            final Set<String> eventLikes = Set<String>.from(
              reactions[targetEventId] ?? <String>{},
            )..add(reaction.pubKey);

            reactions[targetEventId] = eventLikes;
            sFeedReactions.value = reactions;
          }
        });
  }

  // Fetche Nostr profile data for a specific user and caches it.
  Future<void> _resolveMetadata(String pubkey) async {
    // User's metadata already present, skip fetch.
    if (sFeedMetadata.value.containsKey(pubkey)) return;

    try {
      // Load profile (Name, Avatar, etc.) from NDK.
      final Metadata? meta = await getMetadataForPubkey(pubkey);

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
    await _feedSubscription?.cancel();
    await _reactionSubscription?.cancel();
    _feedSubscription = null;
    _reactionSubscription = null;
  }

  // Refresh Feed.
  Future<void> refreshFeed() async {
    sFeedEvents.value = <Nip01Event>[];
    sFeedReactions.value = <String, Set<String>>{};
    await stopFeedSubscriptions();
    startFeedSubscriptions();
  }

  // --- OTHERS ---

  Future<void> updateMetadata(Metadata metadata) async {
    // Illegal action.
    if (sNpub.value == null) return;

    // Broadcast metadata update.
    final Metadata updated = await _ndk.metadata.broadcastMetadata(metadata);

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

  // Delete keys from device.
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

    // Kill subscriptions.
    await stopFeedSubscriptions();
  }

  // Get nsec from secure storage.
  Future<String?> getNsec() async {
    return await _storage.read(key: 'nostr_nsec');
  }
}

// Globalize NostrService.
final NostrService nostrService = NostrService();
