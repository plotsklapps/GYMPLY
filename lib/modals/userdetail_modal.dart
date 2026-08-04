import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:ndk/ndk.dart';

class UserDetailModal extends StatelessWidget {
  const UserDetailModal({
    required this.likers,
    super.key,
  });

  final List<(String, Metadata?)> likers;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                likers.length == 1
                    ? 'USER DETAILS'
                    : 'LIKES (${likers.length})',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(IconUtils.close),
            ),
          ],
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),
                for (final (String, Metadata?) user in likers) ...<Widget>[
                  (() {
                    final String pubkey = user.$1;
                    final Metadata? meta = user.$2;
                    final String name =
                        meta?.name ?? 'User ${pubkey.substring(0, 8)}';
                    final String? avatar = meta?.picture;
                    final String npub = Nip19.encodePubKey(pubkey);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  backgroundImage: isValidHttpUrl(avatar)
                                      ? NetworkImage(avatar!)
                                      : const AssetImage(
                                              'assets/icons/gymplyIcon.png',
                                            )
                                            as ImageProvider,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (meta?.displayName != null &&
                                          meta!.displayName!.isNotEmpty)
                                        Text(
                                          meta.displayName!,
                                          style: theme.textTheme.labelSmall,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (meta?.about != null &&
                                meta!.about!.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                meta.about!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            const Divider(),
                            _UserDetailTile(
                              label: 'NPUB',
                              value: npub,
                              icon: IconUtils.copy,
                            ),
                            if (meta?.nip05 != null && meta!.nip05!.isNotEmpty)
                              _UserDetailTile(
                                label: 'NIP-05',
                                value: meta.nip05!,
                                icon: IconUtils.idCard,
                              ),
                            if (meta?.lud16 != null && meta!.lud16!.isNotEmpty)
                              _UserDetailTile(
                                label: 'LUD-16',
                                value: meta.lud16!,
                                icon: IconUtils.zap,
                              ),
                            if (meta?.website != null &&
                                meta!.website!.isNotEmpty)
                              _UserDetailTile(
                                label: 'WEBSITE',
                                value: meta.website!,
                                icon: IconUtils.link,
                              ),
                          ],
                        ),
                      ),
                    );
                  })(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserDetailTile extends StatelessWidget {
  const _UserDetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            ToastService.showSuccess(
              title: 'Copied to Clipboard',
              subtitle: value,
            );
          },
          icon: Icon(icon, size: 16),
        ),
      ],
    );
  }
}
