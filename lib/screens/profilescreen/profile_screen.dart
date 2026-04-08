import 'package:flutter/material.dart';
import 'package:gymply/modals/importkeys_modal.dart';
import 'package:gymply/screens/profilescreen/keycard_widget.dart';
import 'package:gymply/screens/profilescreen/metadataform_widget.dart';
import 'package:gymply/screens/profilescreen/onboarding_widget.dart';
import 'package:gymply/screens/profilescreen/profileheader_widget.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';
import 'package:signals/signals_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch Nostr keys and metadata from service.
    final String? npub = nostrService.sNpub.watch(context);
    final bool hasNsec = nostrService.sNsec.watch(context);
    final Metadata? metadata = nostrService.sMetadata.watch(context);

    return SafeArea(
      child: Scaffold(
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
                    _ProfileWidget(
                      npub: npub,
                      hasNsec: hasNsec,
                      metadata: metadata,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileWidget extends StatelessWidget {
  const _ProfileWidget({
    required this.npub,
    required this.hasNsec,
    required this.metadata,
  });

  final String npub;
  final bool hasNsec;
  final Metadata? metadata;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 40),
          Text(
            'NOSTR PROFILE',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const Divider(),

          // If only npub is set, show Card.
          if (!hasNsec)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 8),
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

          // If nsec is set, show MetaDataForm.
          MetaDataForm(metadata: metadata, canSign: hasNsec),
          const SizedBox(height: 24),
          Text(
            'NOSTR KEYS',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const Divider(),

          // npub card.
          KeyCard(
            label: 'PUBLIC KEY (npub)',
            keyValue: npub,
            icon: LucideIcons.key,
            isSensitive: false,
          ),
          const SizedBox(height: 8),

          // nsec card.
          if (hasNsec)
            KeyCard(
              label: 'PRIVATE KEY (nsec)',
              onFetchValue: nostrService.getNsec,
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
