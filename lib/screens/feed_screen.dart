import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart' hide Logger;
import 'package:signals/signals_flutter.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() {
    return _FeedScreenState();
  }
}

class _FeedScreenState extends State<FeedScreen> {
  StreamSubscription<Nip01Event>? _subscription;
  StreamSubscription<Nip01Event>? _reactionSubscription;
  bool _isLoading = true;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _startSubscription();
  }

  /// Sets up the Nostr subscription for GYMPLY workout events.
  void _startSubscription() {
    setState(() {
      _isLoading = true;
    });

    _subscription = nostrService.getGymplyFeedStream().listen((
      Nip01Event event,
    ) async {
      // Add event if not already present.
      if (!nostrService.sFeedEvents.value.any(
        (Nip01Event e) => e.id == event.id,
      )) {
        final List<Nip01Event> newList =
            <Nip01Event>[event, ...nostrService.sFeedEvents.value]
              // Sort newest first.
              ..sort(
                (Nip01Event a, Nip01Event b) {
                  return b.createdAt.compareTo(a.createdAt);
                },
              );
        nostrService.sFeedEvents.value = newList;

        // Fetch user profile (Name/Avatar) if we don't have it.
        await _resolveMetadata(event.pubKey);

        // Update reaction subscription to include this new post.
        _updateReactionSubscription();
      }

      if (_isLoading && nostrService.sFeedEvents.value.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Safety timeout: if after 5 seconds we have no data, stop the spinner.
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  /// Subscribes to Kind 7 reactions for all currently visible posts.
  void _updateReactionSubscription() {
    // We don't await here because this is called frequently from a stream listener.
    _reactionSubscription?.cancel();
    final List<String> eventIds = nostrService.sFeedEvents.value
        .map((Nip01Event e) => e.id)
        .toList();

    if (eventIds.isEmpty) return;

    _reactionSubscription = nostrService.getReactionsStream(eventIds).listen((
      Nip01Event reaction,
    ) {
      // Find the 'e' tag to identify which post this reaction belongs to.
      final List<String> eTag = reaction.tags.firstWhere(
        (List<String> t) => t.length >= 2 && t[0] == 'e',
        orElse: () => <String>[],
      );

      if (eTag.isNotEmpty && reaction.content == '💪') {
        final String targetEventId = eTag[1];

        // Update the reaction map.
        final Map<String, Set<String>> reactions =
            Map<String, Set<String>>.from(nostrService.sFeedReactions.value);
        final Set<String> eventLikes = Set<String>.from(
          reactions[targetEventId] ?? <String>{},
        );

        eventLikes.add(reaction.pubKey);
        reactions[targetEventId] = eventLikes;
        nostrService.sFeedReactions.value = reactions;
      }
    });
  }

  /// Fetches Nostr profile data for a specific user.
  Future<void> _resolveMetadata(String pubkey) async {
    if (nostrService.sFeedMetadata.value.containsKey(pubkey)) return;

    try {
      final Metadata? meta = await nostrService.getMetadataForPubkey(pubkey);
      if (meta != null && mounted) {
        final Map<String, Metadata> newMap = Map<String, Metadata>.from(
          nostrService.sFeedMetadata.value,
        );
        newMap[pubkey] = meta;
        nostrService.sFeedMetadata.value = newMap;
      }
    } on Object catch (e) {
      _logger.w('Could not resolve metadata for $pubkey: $e');
    }
  }

  /// Handles the pull-to-refresh logic.
  Future<void> _onRefresh() async {
    nostrService.sFeedEvents.value = <Nip01Event>[];
    nostrService.sFeedReactions.value = <String, Set<String>>{};
    // Here we DO await the cancellations for a clean restart.
    await _subscription?.cancel();
    await _reactionSubscription?.cancel();
    _startSubscription();
    // Brief delay to ensure UI feels responsive.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    // dispose() MUST be synchronous.
    _subscription?.cancel();
    _reactionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Nip01Event> events = nostrService.sFeedEvents.watch(context);
    final Map<String, Metadata> metadataMap = nostrService.sFeedMetadata.watch(
      context,
    );
    final Map<String, Set<String>> reactionsMap = nostrService.sFeedReactions
        .watch(context);

    if (_isLoading && events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('LOADING GYMPLY FEED...'),
          ],
        ),
      );
    }

    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
            const Center(
              child: Column(
                children: <Widget>[
                  Icon(LucideIcons.rss, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No GYMPLY posts found yet.'),
                  Text(
                    'Be the first to share a workout!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (BuildContext context, int index) {
          final Nip01Event event = events[index];
          final Metadata? meta = metadataMap[event.pubKey];
          final Set<String> likes = reactionsMap[event.id] ?? <String>{};
          return _WorkoutPostCard(
            event: event,
            metadata: meta,
            likes: likes,
          );
        },
      ),
    );
  }
}

class _WorkoutPostCard extends StatelessWidget {
  const _WorkoutPostCard({
    required this.event,
    required this.likes,
    this.metadata,
  });

  final Nip01Event event;
  final Metadata? metadata;
  final Set<String> likes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // 1. PARSE CONTENT
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

    // 2. IDENTITY
    final String name =
        metadata?.name ?? 'User ${event.pubKey.substring(0, 8)}';
    final String? avatar = metadata?.picture;

    // 3. REACTION STATE
    final String? myNpub = nostrService.sNpub.value;
    final String myPubkey = myNpub != null ? Nip19.decode(myNpub) : '';
    final bool hasLiked = likes.contains(myPubkey);

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // HEADER (Author Info)
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
              _formatTimestamp(event.createdAt),
              style: theme.textTheme.labelSmall,
            ),
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
                      onPressed: () {
                        nostrService.sendBicepsReaction(event.id);
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

  String _formatTimestamp(int createdAt) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return DateFormat('yyyy, MMMM dd').format(date);
  }
}
