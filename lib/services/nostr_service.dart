import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:signals/signals_flutter.dart';

// Globalize NostrService.
final NostrService nostrService = NostrService();

class NostrService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Ndk _ndk;

  // Signals to track keys. npub is public, nsec is sensitive.
  final Signal<String?> sNpub = Signal<String?>(null, debugLabel: 'sNpub');
  final Signal<String?> sNsec = Signal<String?>(null, debugLabel: 'sNsec');

  // Signal for metadata.
  final Signal<Metadata?> sMetadata = Signal<Metadata?>(
    null,
    debugLabel: 'sMetadata',
  );

  /// Initialize the service by loading keys from secure storage.
  Future<void> init() async {
    // Init NDK with default config.
    _ndk = Ndk.defaultConfig();

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

    if (nsec != null) {
      final String privkeyHex = Nip19.decode(nsec);
      _ndk.accounts.loginPrivateKey(pubkey: pubkeyHex, privkey: privkeyHex);
    } else {
      _ndk.accounts.loginPublicKey(pubkey: pubkeyHex);
    }
  }

  /// Load metadata from relays.
  Future<void> fetchMetadata() async {
    if (sNpub.value == null) return;
    try {
      final String pubkeyHex = Nip19.decode(sNpub.value!);
      final Metadata? meta = await _ndk.metadata.loadMetadata(
        pubkeyHex,
        forceRefresh: true,
      );
      sMetadata.value = meta;
    } catch (e) {
      // Failed to fetch metadata.
    }
  }

  /// Broadcast metadata to relays.
  Future<void> updateMetadata(Metadata metadata) async {
    if (sNpub.value == null) return;
    try {
      final Metadata updated = await _ndk.metadata.broadcastMetadata(metadata);
      sMetadata.value = updated;
    } catch (e) {
      rethrow;
    }
  }

  // Generate a new set of keys and store them securely.
  Future<void> generateKeys() async {
    // Generate raw hex keys using bip340.
    final KeyPair keyPair = Bip340.generatePrivateKey();

    // KeyPair object contains bech32 encoded strings (nsec/npub).
    final String nsec = keyPair.privateKeyBech32!;
    final String npub = keyPair.publicKeyBech32!;

    // Save to secure storage.
    await _storage.write(key: 'nostr_npub', value: npub);
    await _storage.write(key: 'nostr_nsec', value: nsec);

    // Update signals.
    sNpub.value = npub;
    sNsec.value = nsec;

    await _loginToNdk(npub, nsec);
    await fetchMetadata();
  }

  // Save existing keys provided by the user (nsec/npub).
  Future<bool> useExistingKeys(String input) async {
    final String cleanInput = input.trim();
    try {
      if (Nip19.isPrivateKey(cleanInput)) {
        // Scenario A: User provided a private key (nsec).
        final String privateKeyHex = Nip19.decode(cleanInput);
        if (privateKeyHex.isEmpty) return false;

        final String publicKeyHex = Bip340.getPublicKey(privateKeyHex);
        final String npub = Nip19.encodePubKey(publicKeyHex);

        await _storage.write(key: 'nostr_npub', value: npub);
        await _storage.write(key: 'nostr_nsec', value: cleanInput);

        // Set Signals.
        sNpub.value = npub;
        sNsec.value = cleanInput;

        await _loginToNdk(npub, cleanInput);
        await fetchMetadata();
        return true;
      } else if (Nip19.isPubkey(cleanInput)) {
        // Scenario B: User provided a public key (npub) - Watch-only mode.
        await _storage.write(key: 'nostr_npub', value: cleanInput);
        await _storage.delete(key: 'nostr_nsec');

        // Set Signals.
        sNpub.value = cleanInput;
        // No private key available.
        sNsec.value = null;

        await _loginToNdk(cleanInput, null);
        await fetchMetadata();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete keys from the device.
  Future<void> logout() async {
    await _storage.delete(key: 'nostr_npub');
    await _storage.delete(key: 'nostr_nsec');
    _ndk.accounts.logout();
    sNpub.value = null;
    sNsec.value = null;
    sMetadata.value = null;
  }
}
