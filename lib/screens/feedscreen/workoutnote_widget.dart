import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';

class WorkoutNote extends StatelessWidget {
  const WorkoutNote({
    required this.event,
    required this.likes,
    super.key,
    this.metadata,
  });

  final Nip01Event event;
  final Metadata? metadata;
  final Set<String> likes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Parse content.
    Map<String, dynamic> content = <String, dynamic>{};
    try {
      final dynamic decoded = jsonDecode(event.content);
      if (decoded is Map<String, dynamic>) {
        content = decoded;
      }
    } on Object catch (_) {
      return const SizedBox.shrink();
    }

    final String? imageUrl = content['image'] as String?;
    if (imageUrl == null || content['app'] != 'GYMPLY.') {
      return const SizedBox.shrink();
    }

    // Fetch identity.
    final String name =
        metadata?.name ?? 'User ${event.pubKey.substring(0, 8)}';
    final String? avatar = metadata?.picture;

    // Check ownership and reaction state.
    final String? myNpub = nostrService.sNpub.value;
    final String myPubkey = myNpub != null ? Nip19.decode(myNpub) : '';
    final bool isMine = event.pubKey == myPubkey;
    final bool hasLiked = likes.contains(myPubkey);

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header (author info).
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: avatar != null
                  ? NetworkImage(avatar)
                  : const AssetImage('assets/icons/gymplyIcon.png'),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              event.createdAt.formatWorkoutDate(),
              style: theme.textTheme.labelSmall,
            ),
            trailing: isMine
                ? PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.ellipsisVertical),
                    onSelected: (String value) async {
                      if (value == 'delete') {
                        await nostrService.deleteWorkoutNote(event.id);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Delete',
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.trash,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                  )
                : null,
          ),

          // BODY (The Workout Image)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder:
                (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) =>
                    Container(
                      height: 200,
                      color: theme.colorScheme.errorContainer,
                      child: const Center(child: Text('Image failed to load')),
                    ),
          ),

          // FOOTER (Actions)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                // BICEPS FLEX (Like)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        LucideIcons.bicepsFlexed,
                        color: hasLiked ? theme.colorScheme.secondary : null,
                      ),
                      onPressed: () async {
                        await nostrService.sendBicepsReaction(event.id);
                      },
                    ),
                    if (likes.isNotEmpty)
                      Text(
                        '${likes.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: hasLiked ? theme.colorScheme.secondary : null,
                          fontWeight: hasLiked
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.messageSquare),
                  onPressed: () {
                    ToastService.showWarning(
                      title: 'Feature Coming!',
                      subtitle: 'Come back soon to comment on workouts',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.zap),
                  color: Colors.amber,
                  onPressed: () {
                    ToastService.showWarning(
                      title: 'Feature Coming!',
                      subtitle: 'Come back soon to zap workouts',
                    );
                  },
                ),
                const Spacer(),
                const Icon(LucideIcons.dumbbell, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'GYMPLY.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
