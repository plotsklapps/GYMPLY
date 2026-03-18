import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymply/screens/feedscreen/workoutnote_widget.dart';
import 'package:gymply/services/nostr_service.dart';
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
  @override
  void initState() {
    super.initState();
    // Initialize the Nostr subscriptions.
    nostrService.startFeedSubscriptions();
  }

  // Handle pull-to-refresh logic.
  Future<void> _onRefresh() async {
    await nostrService.refreshFeed();
    // Brief delay to ensure UI feels responsive.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    // Kill the Nostr subscriptions.
    unawaited(nostrService.stopFeedSubscriptions());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch Signals.
    final List<Nip01Event> events = nostrService.sFeedEvents.watch(context);
    final Map<String, Metadata> metadataMap = nostrService.sFeedMetadata.watch(
      context,
    );
    final Map<String, Set<String>> reactionsMap = nostrService.sFeedReactions
        .watch(context);
    final bool isLoading = nostrService.sIsLoadingFeed.watch(context);

    // Loading Spinner.
    if (isLoading && events.isEmpty) {
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

    // Fallback for no posts (or relay issues).
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
          return WorkoutNote(
            event: event,
            metadata: meta,
            likes: likes,
          );
        },
      ),
    );
  }
}
