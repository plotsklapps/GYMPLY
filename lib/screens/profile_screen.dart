import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Nostr keys and metadata from service.
    final String? npub = nostrService.sNpub.watch(context);
    final String? nsec = nostrService.sNsec.watch(context);
    final Metadata? metadata = nostrService.sMetadata.watch(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            if (metadata?.picture != null && metadata!.picture!.isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(metadata.picture!),
                onBackgroundImageError: (_, _) => const Icon(
                  LucideIcons.userRound,
                  size: 80,
                ),
              )
            else
              const Icon(
                LucideIcons.userRound,
                size: 80,
              ),
            const SizedBox(height: 24),
            if (npub == null)
              _buildOnboarding(context, theme)
            else
              _buildProfile(context, theme, npub, nsec, metadata),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboarding(BuildContext context, ThemeData theme) {
    return Column(
      children: <Widget>[
        Text(
          'NOSTR & GYMPLY.',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Nostr is a decentralized protocol for publishing and reading '
          'messages. There is no central server: data is sent to '
          'public “relays,” and anyone can read it. Every user is '
          'identified only by a public key and signs their posts '
          'with a private key, so identity and data ownership stay '
          'with the user.\n\n'
          'npub = your public key. It identifies you on Nostr and lets '
          'others read your posts and profile.\n\n'
          'nsec = your private key. It proves that you are the owner '
          'of your account and allows you to publish posts. '
          'It is crucial the nsec is never shared.\n\n'
          'GYMPLY. stores your keys locally only. Nothing is uploaded or '
          'synced unless you explicitly connect to Nostr.\n\n'
          'When you enable Nostr, GYMPLY. publishes your workouts as '
          'GYMPLY‑specific events and reads events from other users '
          'who also use GYMPLY.\n\n'
          'Nostr is completely optional. You can use GYMPLY fully '
          'offline with no account, no keys, and no data leaving '
          'your device.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () async {
            await nostrService.generateKeys();
            if (context.mounted) {
              toastification.show(
                context: context,
                type: ToastificationType.success,
                title: const Text('Keys Generated!'),
                autoCloseDuration: const Duration(seconds: 3),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Create New Keys'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            await _showImportKeysDialog(context);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Use Existing Keys'),
        ),
      ],
    );
  }

  Widget _buildProfile(
    BuildContext context,
    ThemeData theme,
    String npub,
    String? nsec,
    Metadata? metadata,
  ) {
    return Column(
      children: <Widget>[
        Text(
          'NOSTR ACCOUNT',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (nsec == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(LucideIcons.eye, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Read-only Mode Active',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can see the GYMPLY. feed, but you cannot post '
                      'your workouts or react to other users. Import your '
                      'nsec to enable posting.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await _showImportKeysDialog(context);
                            },
                            icon: const Icon(LucideIcons.lock),
                            label: const Text('Import Private Key (nsec)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Metadata form.
        _MetadataForm(metadata: metadata, canSign: nsec != null),
        const SizedBox(height: 32),

        // npub card.
        _KeyCard(
          label: 'PUBLIC KEY (npub)',
          keyValue: npub,
          icon: LucideIcons.key,
          isSensitive: false,
        ),
        const SizedBox(height: 16),

        // nsec card.
        if (nsec != null)
          _KeyCard(
            label: 'PRIVATE KEY (nsec)',
            keyValue: nsec,
            icon: LucideIcons.lock,
            isSensitive: true,
          ),

        const SizedBox(height: 32),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await nostrService.logout();
                },
                icon: const Icon(LucideIcons.logOut),
                label: const Text('Logout and delete keys from device'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _showImportKeysDialog(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    return ModalService.showModal(
      context: context,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              // Empty SizedBox to balance Icon and Text.
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'IMPORT KEYS',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Pop and return false.
                  Navigator.pop(context, false);
                },
                icon: const Icon(LucideIcons.circleX),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Enter your nsec for full access or npub for watch-only mode.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'nsec or npub',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Pop and return false.
                    Navigator.pop(context, false);
                  },
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final String input = controller.text.trim();
                    final bool success = await nostrService.useExistingKeys(
                      input,
                    );
                    if (context.mounted) {
                      Navigator.pop(context, success);
                      if (success) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          title: const Text('Keys Imported!'),
                          autoCloseDuration: const Duration(seconds: 3),
                        );
                      } else {
                        toastification.show(
                          context: context,
                          type: ToastificationType.error,
                          title: const Text('Invalid Key!'),
                          description: const Text(
                            'Please check your npub or nsec.',
                          ),
                          autoCloseDuration: const Duration(seconds: 3),
                        );
                      }
                    }
                  },
                  child: const Text('IMPORT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetadataForm extends StatefulWidget {
  const _MetadataForm({required this.metadata, required this.canSign});

  final Metadata? metadata;
  final bool canSign;

  @override
  State<_MetadataForm> createState() => _MetadataFormState();
}

class _MetadataFormState extends State<_MetadataForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _pictureController = TextEditingController();
  final TextEditingController _bannerController = TextEditingController();
  final TextEditingController _nip05Controller = TextEditingController();
  final TextEditingController _lud16Controller = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didUpdateWidget(_MetadataForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metadata != oldWidget.metadata) {
      _populateFields();
    }
  }

  void _populateFields() {
    if (widget.metadata != null) {
      _nameController.text = widget.metadata!.name ?? '';
      _displayNameController.text = widget.metadata!.displayName ?? '';
      _aboutController.text = widget.metadata!.about ?? '';
      _pictureController.text = widget.metadata!.picture ?? '';
      _bannerController.text = widget.metadata!.banner ?? '';
      _nip05Controller.text = widget.metadata!.nip05 ?? '';
      _lud16Controller.text = widget.metadata!.lud16 ?? '';
      _websiteController.text = widget.metadata!.website ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _aboutController.dispose();
    _pictureController.dispose();
    _bannerController.dispose();
    _nip05Controller.dispose();
    _lud16Controller.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'PROFILE DETAILS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        _MetadataTextField(
          label: 'Name',
          controller: _nameController,
          hint: 'Your unique name',
        ),
        _MetadataTextField(
          label: 'Display Name',
          controller: _displayNameController,
          hint: 'How people see you',
        ),
        _MetadataTextField(
          label: 'About',
          controller: _aboutController,
          hint: 'Tell the world about your gains',
          maxLines: 3,
        ),
        _MetadataTextField(
          label: 'Picture URL',
          controller: _pictureController,
          hint: 'https://example.com/avatar.jpg',
        ),
        _MetadataTextField(
          label: 'Banner URL',
          controller: _bannerController,
          hint: 'https://example.com/banner.jpg',
        ),
        _MetadataTextField(
          label: 'NIP-05 Verification',
          controller: _nip05Controller,
          hint: 'user@domain.com',
        ),
        _MetadataTextField(
          label: 'Lightning Address (LUD-16)',
          controller: _lud16Controller,
          hint: 'user@getalby.com',
        ),
        _MetadataTextField(
          label: 'Website',
          controller: _websiteController,
          hint: 'https://yourwebsite.com',
        ),
        const SizedBox(height: 24),
        if (widget.canSign)
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveMetadata,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save),
            label: const Text('Save Profile Changes'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          )
        else
          const Text(
            'You must import your private key (nsec) to update your profile.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Future<void> _saveMetadata() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final Metadata metadata =
          widget.metadata?.copyWith() ??
                Metadata(pubKey: Nip19.decode(nostrService.sNpub.value!))
            ..name = _nameController.text.trim()
            ..displayName = _displayNameController.text.trim()
            ..about = _aboutController.text.trim()
            ..picture = _pictureController.text.trim()
            ..banner = _bannerController.text.trim()
            ..nip05 = _nip05Controller.text.trim()
            ..lud16 = _lud16Controller.text.trim()
            ..website = _websiteController.text.trim();

      await nostrService.updateMetadata(metadata);

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Profile Updated!'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } on Object catch (e) {
      // Show toast to user.
      ToastService.showError(title: 'Update Failed', subtitle: '$e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _MetadataTextField extends StatelessWidget {
  const _MetadataTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _KeyCard extends StatefulWidget {
  const _KeyCard({
    required this.label,
    required this.keyValue,
    required this.icon,
    required this.isSensitive,
  });

  final String label;
  final String keyValue;
  final IconData icon;
  final bool isSensitive;

  @override
  State<_KeyCard> createState() {
    return _KeyCardState();
  }
}

class _KeyCardState extends State<_KeyCard> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(widget.icon, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.isSensitive && _isHidden
                        ? '••••••••••••••••••••••••••••••••'
                        : widget.keyValue,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSensitive)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isHidden = !_isHidden;
                      });
                    },
                    icon: Icon(
                      _isHidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 16,
                    ),
                  ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.keyValue),
                    );
                    // Show toast to user.
                    ToastService.showSuccess(
                      title: 'Copied to Clipboard',
                      subtitle: 'Use the key at your own discretion',
                    );
                  },
                  icon: const Icon(LucideIcons.copy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
