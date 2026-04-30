import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Fixed header.
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                likers.length > 1 ? 'LIKED BY' : 'USER PROFILE',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),
                ...likers.asMap().entries.map((
                  MapEntry<int, (String, Metadata?)> entry,
                ) {
                  final int index = entry.key;
                  final (String pubkey, Metadata? metadata) = entry.value;
                  final String npub = Nip19.encodePubKey(pubkey);
                  final String name =
                      metadata?.name ?? 'User ${pubkey.substring(0, 8)}';
                  final String? avatar = metadata?.picture;
                  final String? bio = metadata?.about;
                  final String? nip05 = metadata?.nip05;
                  final String? lud16 = metadata?.lud16;
                  final String? website = metadata?.website;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: avatar != null
                                ? NetworkImage(avatar)
                                : const AssetImage(
                                        'assets/icons/gymplyIcon.png',
                                      )
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        npub,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: Colors.grey,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: npub),
                                        );
                                        ToastService.showSuccess(
                                          title: 'Npub Copied',
                                          subtitle:
                                              'Public key copied to clipboard',
                                        );
                                      },
                                      child: Icon(
                                        LucideIcons.copy,
                                        size: 14,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (nip05 != null && nip05.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Icon(
                              LucideIcons.badgeCheck,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                nip05,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (lud16 != null && lud16.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              LucideIcons.zap,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lud16,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (website != null && website.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              LucideIcons.link,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                website,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (bio != null && bio.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          bio,
                          style: theme.textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (index < likers.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
