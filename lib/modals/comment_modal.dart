import 'package:flutter/material.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';
import 'package:signals/signals_flutter.dart';

class CommentModal extends StatefulWidget {
  const CommentModal({
    required this.event,
    required this.imageUrl,
    required this.authorMetadata,
    super.key,
  });

  final Nip01Event event;
  final String imageUrl;
  final Metadata? authorMetadata;

  @override
  State<CommentModal> createState() {
    return _CommentModalState();
  }
}

class _CommentModalState extends State<CommentModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _replyToId;
  String? _replyToName;
  String? _replyToPubKey;

  @override
  void initState() {
    super.initState();
    nostrService.startCommentSubscription(widget.event.id);
  }

  @override
  void dispose() {
    nostrService.stopCommentSubscription();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) return;

    await nostrService.sendComment(
      content: _controller.text.trim(),
      rootId: widget.event.id,
      rootAuthorPubKey: widget.event.pubKey,
      replyToId: _replyToId,
      replyToPubKey: _replyToPubKey,
    );

    _controller.clear();
    setState(() {
      _replyToId = null;
      _replyToName = null;
      _replyToPubKey = null;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final List<Nip01Event> comments = nostrService.sActiveWorkoutComments.watch(
      context,
    );
    final Map<String, Metadata> metadataMap = nostrService.sFeedMetadata.watch(
      context,
    );
    final Map<String, Set<String>> reactionsMap = nostrService.sFeedReactions
        .watch(context);

    final String? myNpub = nostrService.sNpub.value;
    final String myPubKey = myNpub != null ? Nip19.decode(myNpub) : '';
    final bool isWorkoutAuthor = widget.event.pubKey == myPubKey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // --- FIXED HEADER ---
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'WORKOUT COMMENTS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),

        // --- SCROLLABLE BODY ---
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              // Mini Workout Header
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: widget.authorMetadata?.picture != null
                      ? NetworkImage(widget.authorMetadata!.picture!)
                      : const AssetImage('assets/icons/gymplyIcon.png')
                            as ImageProvider,
                ),
                title: Text(
                  widget.authorMetadata?.name ?? 'Workout Poster',
                  style: theme.textTheme.bodyLarge,
                ),
                trailing: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Divider(),

              // No comments yet.
              if (comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  child: Center(
                    child: Text(
                      'No comments yet. Be the first to comment on this '
                      'workout!',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),

              // Comments List.
              ...comments.map((Nip01Event comment) {
                final Metadata? meta = metadataMap[comment.pubKey];
                final String commenterName =
                    meta?.name ?? 'User ${comment.pubKey.substring(0, 8)}';
                final bool isCommentAuthor = comment.pubKey == myPubKey;

                // Check if comment is a reply.
                // Reply is any comment that tags another event as 'reply'.
                // Only indent ONCE for all replies to keep it readable.
                final bool isReply = comment.tags.any(
                  (List<String> t) {
                    return t.length >= 4 && t[0] == 'e' && t[3] == 'reply';
                  },
                );

                return InkWell(
                  onTap: isWorkoutAuthor
                      ? () {
                          setState(() {
                            _replyToId = comment.id;
                            _replyToName = commenterName;
                            _replyToPubKey = comment.pubKey;
                          });
                          _focusNode.requestFocus();
                        }
                      : null,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                      left: isReply ? 24 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (isReply)
                          Container(
                            width: 2,
                            height: 32,
                            margin: const EdgeInsets.only(right: 12),
                            color: theme.colorScheme.outlineVariant,
                          ),
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: meta?.picture != null
                              ? NetworkImage(meta!.picture!)
                              : const AssetImage('assets/icons/gymplyIcon.png')
                                    as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        commenterName,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (comment.pubKey == widget.event.pubKey)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Text(
                                            '• AUTHOR',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    comment.createdAt.formatWorkoutDate(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                comment.content,
                                style: theme.textTheme.bodySmall,
                              ),
                              Row(
                                children: <Widget>[
                                  // Delete ONLY possible if comment Author.
                                  if (isCommentAuthor)
                                    IconButton(
                                      onPressed: () async {
                                        await nostrService.deleteComment(
                                          comment.id,
                                          widget.event.id,
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        LucideIcons.trash,
                                        color: theme.colorScheme.error,
                                        size: 14,
                                      ),
                                    ),
                                  // Reply ONLY possible if workout Author.
                                  if (isWorkoutAuthor)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _replyToId = comment.id;
                                          _replyToName = commenterName;
                                          _replyToPubKey = comment.pubKey;
                                        });
                                        _focusNode.requestFocus();
                                      },
                                      icon: const Icon(
                                        LucideIcons.messageSquare,
                                        size: 14,
                                      ),
                                    ),
                                  // Like possible for everyone.
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () async {
                                          await nostrService.sendBicepsReaction(
                                            comment.id,
                                            rootId: widget.event.id,
                                          );
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          LucideIcons.bicepsFlexed,
                                          size: 14,
                                          color:
                                              reactionsMap[comment.id]
                                                      ?.contains(myPubKey) ??
                                                  false
                                              ? theme.colorScheme.secondary
                                              : null,
                                        ),
                                      ),
                                      if (reactionsMap[comment.id]
                                              ?.isNotEmpty ??
                                          false)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Text(
                                            '${reactionsMap[comment.id]!.length}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      reactionsMap[comment.id]!
                                                          .contains(myPubKey)
                                                      ? theme
                                                            .colorScheme
                                                            .secondary
                                                      : theme
                                                            .colorScheme
                                                            .primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(),

        // --- FIXED FOOTER ---
        if (_replyToName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: <Widget>[
                Text(
                  'Replying to @$_replyToName',
                  style: theme.textTheme.labelSmall,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _replyToId = null;
                    _replyToName = null;
                    _replyToPubKey = null;
                  }),
                  child: const Icon(LucideIcons.x, size: 14),
                ),
              ],
            ),
          ),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: 140,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Flex your thoughts...',
                  border: InputBorder.none,
                  counterText: '', // We use our own counter below
                ),
                onChanged: (String value) => setState(() {}),
              ),
            ),
            Column(
              children: <Widget>[
                Text(
                  '${_controller.text.length}/140',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _controller.text.length >= 140
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : _sendComment,
                  icon: Icon(
                    LucideIcons.sendHorizontal,
                    color: _controller.text.trim().isEmpty
                        ? Colors.grey
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
