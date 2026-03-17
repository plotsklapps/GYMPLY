import 'package:flutter/material.dart';
import 'package:gymply/modals/importkeys_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/nostr_service.dart';

class NostrOnboarding extends StatelessWidget {
  const NostrOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
      child: Column(
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
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await nostrService.generateKeys();
                  },
                  child: const Text('Create New Keys'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ModalService.showModal(
                      context: context,
                      child: const ImportKeysModal(),
                    );
                  },
                  child: const Text('Use Existing Keys'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
