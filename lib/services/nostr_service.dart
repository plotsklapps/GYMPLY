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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  late Ndk _ndk;

  // Custom Kind for GYMPLY workout posts.
  // Switched to 6742 to avoid collision with Geohash bots on 2242.
  static const int kGymplyWorkoutKind = 6742;

  // Static list of 10 reliable Nostr relays.
  // Removed purplepag.es as it blocks custom event kinds.
  final List<String> _defaultRelays = <String>[
    'wss://relay.primal.net',
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.snort.social',
    'wss://offchain.pub',
    'wss://nostr.mom',
    'wss://nostr.bitcoiner.social',
  ];

  // Default Blossom servers for image hosting.
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
  final Signal<String?> sNsec = Signal<String?>(null, debugLabel: 'sNsec');

  // Signal for own profile metadata.
  final Signal<Metadata?> sMetadata = Signal<Metadata?>(
    null,
    debugLabel: 'sMetadata',
  );

  // Global Signal for Feed Events.
  final Signal<List<Nip01Event>> sFeedEvents = Signal<List<Nip01Event>>(
    <Nip01Event>[],
    debugLabel: 'sFeedEvents',
  );

  // Global Signal for Metadata Map (pubkey -> Metadata).
  final Signal<Map<String, Metadata>> sFeedMetadata =
      Signal<Map<String, Metadata>>(
        <String, Metadata>{},
        debugLabel: 'sFeedMetadata',
      );

  // Global Signal for Reactions (eventId -> Set of Pubkeys who liked with 💪).
  final Signal<Map<String, Set<String>>> sFeedReactions =
      Signal<Map<String, Set<String>>>(
        <String, Set<String>>{},
        debugLabel: 'sFeedReactions',
      );

  // --- METHODS ---

  // Initialize service.
  Future<void> init() async {
    _ndk = Ndk(
      NdkConfig(
        bootstrapRelays: _defaultRelays,
        cache: MemCacheManager(),
        eventVerifier: Bip340EventVerifier(),
      ),
    );

    final String? npub = await _storage.read(key: 'nostr_npub');
    final String? nsec = await _storage.read(key: 'nostr_nsec');
    sNpub.value = npub;
    sNsec.value = nsec;

    if (npub != null) {
      await _loginToNdk(npub, nsec);
      await fetchMetadata();
    }
  }

  Future<void> _loginToNdk(String npub, String? nsec) async {
    final String pubkeyHex = Nip19.decode(npub);

    // If npub already exists in NDK, remove it first.
    if (_ndk.accounts.hasAccount(pubkeyHex)) {
      _ndk.accounts.removeAccount(pubkey: pubkeyHex);
    }

    if (nsec != null) {
      final String privkeyHex = Nip19.decode(nsec);
      _ndk.accounts.loginPrivateKey(pubkey: pubkeyHex, privkey: privkeyHex);
    } else {
      _ndk.accounts.loginPublicKey(pubkey: pubkeyHex);
    }
  }

  // Load profile for a specific pubkey (hex or npub).
  Future<Metadata?> getMetadataForPubkey(String pubkey) async {
    final String hex = pubkey.startsWith('npub')
        ? Nip19.decode(pubkey)
        : pubkey;
    try {
      return await _ndk.metadata.loadMetadata(hex);
    } on Object catch (e) {
      _logger.w('Failed to load metadata for $pubkey: $e');
      return null;
    }
  }

  // Load OWN metadata.
  Future<void> fetchMetadata() async {
    if (sNpub.value == null) return;
    final Metadata? meta = await getMetadataForPubkey(sNpub.value!);
    if (meta != null) {
      sMetadata.value = meta;
      _logger.i('Metadata fetched successfully');
    }
  }

  // Publish workout image.
  Future<void> publishWorkoutPost({required Uint8List imageBytes}) async {
    if (sNsec.value == null) throw Exception('No Private Key found.');

    // 1. UPLOAD IMAGE
    final List<BlobUploadResult> uploadResults = await _ndk.blossom.uploadBlob(
      data: imageBytes,
      serverUrls: _defaultBlossomServers,
      contentType: 'image/png',
    );

    final BlobUploadResult? success = uploadResults
        .cast<BlobUploadResult?>()
        .firstWhere(
          (BlobUploadResult? r) =>
              r != null && r.success && r.descriptor != null,
          orElse: () => null,
        );

    if (success == null) throw Exception('Image upload failed.');

    final String imageUrl = success.descriptor!.url;

    // 2. CREATE EVENT
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

    // 3. BROADCAST (Async)
    unawaited(
      _ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture.then((_) {
        _logger.i('Workout post broadcast confirmed by relays.');
      }),
    );

    // 4. INSTANT UI INJECTION
    final List<Nip01Event> newList = <Nip01Event>[event, ...sFeedEvents.value];
    newList.sort(
      (Nip01Event a, Nip01Event b) => b.createdAt.compareTo(a.createdAt),
    );
    sFeedEvents.value = newList;
  }

  /// Sends a "Like" (Kind 7) with a Biceps emoji.
  Future<void> sendBicepsReaction(String eventId) async {
    if (sNsec.value == null) return;

    final String myPubkey = Nip19.decode(sNpub.value!);

    // 1. Optimistic UI update.
    final Map<String, Set<String>> reactions = Map.from(sFeedReactions.value);
    final Set<String> eventLikes = Set.from(reactions[eventId] ?? <String>{});

    if (eventLikes.contains(myPubkey)) return; // Already liked.

    eventLikes.add(myPubkey);
    reactions[eventId] = eventLikes;
    sFeedReactions.value = reactions;

    // 2. Create Kind 7 event.
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
        ], // Self-tag as receiver in this simple logic
      ],
    );

    // 3. Broadcast.
    try {
      await _ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;
    } on Object catch (e) {
      _logger.e('Failed to send reaction: $e');
    }
  }

  // Subscription for the global GYMPLY feed.
  Stream<Nip01Event> getGymplyFeedStream() {
    return _ndk.requests
        .subscription(
          name: 'gymply-global-feed',
          filter: Filter(kinds: <int>[kGymplyWorkoutKind], limit: 50),
        )
        .stream;
  }

  /// Subscription for reactions related to the currently visible posts.
  Stream<Nip01Event> getReactionsStream(List<String> eventIds) {
    if (eventIds.isEmpty) return const Stream.empty();
    return _ndk.requests
        .subscription(
          name: 'gymply-reactions',
          filter: Filter(kinds: <int>[7], eTags: eventIds),
        )
        .stream;
  }

  Future<void> updateMetadata(Metadata metadata) async {
    if (sNpub.value == null) return;
    final Metadata updated = await _ndk.metadata.broadcastMetadata(metadata);
    sMetadata.value = updated;
  }

  Future<bool> generateKeys() async {
    try {
      final KeyPair keyPair = Bip340.generatePrivateKey();
      await _storage.write(key: 'nostr_npub', value: keyPair.publicKeyBech32);
      await _storage.write(key: 'nostr_nsec', value: keyPair.privateKeyBech32);
      sNpub.value = keyPair.publicKeyBech32;
      sNsec.value = keyPair.privateKeyBech32;
      await _loginToNdk(sNpub.value!, sNsec.value);
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

  Future<bool> useExistingKeys(String input) async {
    final String clean = input.trim();
    try {
      if (Nip19.isPrivateKey(clean)) {
        final String privHex = Nip19.decode(clean);
        final String pubHex = Bip340.getPublicKey(privHex);
        final String npub = Nip19.encodePubKey(pubHex);
        await _storage.write(key: 'nostr_npub', value: npub);
        await _storage.write(key: 'nostr_nsec', value: clean);
        sNpub.value = npub;
        sNsec.value = clean;
      } else if (Nip19.isPubkey(clean)) {
        await _storage.write(key: 'nostr_npub', value: clean);
        await _storage.delete(key: 'nostr_nsec');
        sNpub.value = clean;
        sNsec.value = null;
      } else {
        return false;
      }
      await _loginToNdk(sNpub.value!, sNsec.value);
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

  Future<void> logout() async {
    await _storage.delete(key: 'nostr_npub');
    await _storage.delete(key: 'nostr_nsec');
    _ndk.accounts.logout();
    sNpub.value = null;
    sNsec.value = null;
    sMetadata.value = null;
    sFeedEvents.value = <Nip01Event>[];
    sFeedMetadata.value = <String, Metadata>{};
    sFeedReactions.value = <String, Set<String>>{};
  }
}

final NostrService nostrService = NostrService();
