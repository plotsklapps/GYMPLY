import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gymply/modals/comment_modal.dart';
import 'package:gymply/modals/userdetail_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';
import 'package:signals/signals_flutter.dart';

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

    final Map<String, Metadata> metadataMap = nostrService.sFeedMetadata.watch(
      context,
    );

    // List of people who liked this post.
    final List<(String, Metadata?)> likers = likes.map((String pk) {
      return (pk, metadataMap[pk]);
    }).toList();

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

    final Map<String, Set<String>> commentsMap = nostrService.sFeedComments
        .watch(context);
    final Set<String> commentIds = commentsMap[event.id] ?? <String>{};

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header: author info.
          InkWell(
            onTap: () async {
              await ModalService.showModal(
                context: context,
                child: UserDetailModal(
                  likers: <(String, Metadata?)>[(event.pubKey, metadata)],
                ),
              );
            },
            child: ListTile(
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
                      icon: const Icon(LucideIcons.circleEllipsis),
                      onSelected: (String value) async {
                        if (value == 'delete') {
                          await nostrService.deleteWorkoutNote(event.id);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
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
                        ];
                      },
                    )
                  : null,
            ),
          ),

          // Body: Workout Image.
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

          // Footer: Actions.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(LucideIcons.messageSquare),
                      onPressed: () async {
                        await ModalService.showModal(
                          context: context,
                          child: CommentModal(
                            event: event,
                            imageUrl: imageUrl,
                            authorMetadata: metadata,
                          ),
                        );
                      },
                    ),
                    if (commentIds.isNotEmpty)
                      Text(
                        '${commentIds.length}',
                        style: theme.textTheme.labelLarge,
                      ),
                  ],
                ),

                const Spacer(),

                // Like button (biceps).
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
                    if (likes.isNotEmpty) ...<Widget>[
                      Text(
                        '${likes.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasLiked ? theme.colorScheme.secondary : null,
                          fontWeight: hasLiked
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: () async {
                            // Show 'likers' modal.
                            await ModalService.showModal(
                              context: context,
                              child: UserDetailModal(likers: likers),
                            );
                          },
                          // Stack of 'likers' avatars.
                          child: SizedBox(
                            height: 24,
                            width:
                                24 +
                                (likers.length > 1
                                        ? (likers.length > 5
                                              ? 4
                                              : likers.length - 1)
                                        : 0) *
                                    14.0,
                            child: Stack(
                              children: List<Widget>.generate(
                                likers.length > 5 ? 5 : likers.length,
                                (int i) {
                                  final String? avatarUrl =
                                      likers[i].$2?.picture;
                                  return Positioned(
                                    left: i * 14.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.cardColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 11,
                                        backgroundColor:
                                            theme.colorScheme.secondary,
                                        backgroundImage:
                                            avatarUrl != null &&
                                                avatarUrl.isNotEmpty
                                            ? NetworkImage(avatarUrl)
                                            : const AssetImage(
                                                    'assets/icons/gymplyIcon.png',
                                                  )
                                                  as ImageProvider,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
