import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/modals/importkeys_modal.dart';
import 'package:gymply/screens/profilescreen/metadataform_widget.dart';
import 'package:gymply/screens/profilescreen/onboarding_widget.dart';
import 'package:gymply/screens/profilescreen/profileheader_widget.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';
import 'package:signals/signals_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: <Widget>[
            // Banner and Avatar.
            ProfileHeader(metadata: metadata),

            Column(
              children: <Widget>[
                if (npub == null)
                  const NostrOnboarding()
                else
                  _ProfileWidget(npub: npub, nsec: nsec, metadata: metadata),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileWidget extends StatelessWidget {
  const _ProfileWidget({
    required this.npub,
    required this.nsec,
    required this.metadata,
  });

  final String npub;
  final String? nsec;
  final Metadata? metadata;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                              await ModalService.showModal(
                                context: context,
                                child: const ImportKeysModal(),
                              );
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
        MetaDataForm(metadata: metadata, canSign: nsec != null),
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
            keyValue: nsec!,
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
