import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/image_service.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/share_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

// Toggleable metrics.
enum ShareableMetric {
  volume('VOLUME', 'kg'),
  sets('SETS', ''),
  duration('DURATION', ''),
  distance('DISTANCE', 'km'),
  calories('CALORIES', 'kcal'),
  reps('REPS', ''),
  exercises('EXERCISES', '')
  ;

  const ShareableMetric(this.label, this.unit);
  final String label;
  final String unit;
}

class ShareToSocialsModal extends StatefulWidget {
  const ShareToSocialsModal({
    required this.workout,
    super.key,
  });

  final Workout workout;

  @override
  State<ShareToSocialsModal> createState() {
    return _ShareToSocialsModalState();
  }
}

class _ShareToSocialsModalState extends State<ShareToSocialsModal> {
  final GlobalKey _boundaryKey = GlobalKey();

  // Toggles initialized in initState.
  late bool _showPhotos;
  late bool _showNotes;
  // Set to false, to prevent double posting.
  bool _postToNostr = false;
  bool _isSharing = false;

  // Default to share volume, sets & duration.
  final List<ShareableMetric> _selectedMetrics = <ShareableMetric>[
    ShareableMetric.volume,
    ShareableMetric.sets,
    ShareableMetric.duration,
  ];

  List<File> _loadedImages = <File>[];

  @override
  void initState() {
    super.initState();

    // Only show if content exists.
    _showPhotos = widget.workout.imagePaths.isNotEmpty;
    _showNotes = widget.workout.notes.isNotEmpty;

    // Fire and forget image loader.
    unawaited(_loadImages());
  }

  Future<void> _loadImages() async {
    final List<File> files = <File>[];
    for (final String path in widget.workout.imagePaths) {
      final String absolutePath = await imageService.getAbsolutePath(path);
      files.add(File(absolutePath));
    }
    if (mounted) {
      setState(() {
        _loadedImages = files;
      });
    }
  }

  void _toggleMetric(ShareableMetric metric) {
    setState(() {
      if (_selectedMetrics.contains(metric)) {
        if (_selectedMetrics.length > 1) {
          _selectedMetrics.remove(metric);
        }
      } else {
        if (_selectedMetrics.length < 3) {
          _selectedMetrics.add(metric);
        }
      }
    });
  }

  String _getMetricValue(ShareableMetric metric) {
    return switch (metric) {
      ShareableMetric.volume =>
        widget.workout.totalStrengthVolume.toStringAsFixed(0),
      ShareableMetric.sets => widget.workout.totalSets.toString(),
      ShareableMetric.duration => widget.workout.totalDuration.formatHHMM(),
      ShareableMetric.distance =>
        widget.workout.totalCardioDistance.toStringAsFixed(1),
      ShareableMetric.calories => widget.workout.totalCardioCalories.toString(),
      ShareableMetric.reps => widget.workout.totalReps.toString(),
      ShareableMetric.exercises => widget.workout.exerciseCount.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch if the user has a private key to enable Nostr sharing.
    final bool canPostToNostr = nostrService.sNsec.watch(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SHARE WORKOUT',
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
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),

        // --- PREVIEW CARD (RepaintBoundary) ---
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Header: Branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Image.asset('assets/icons/gymplyIcon.png', height: 64),
                        Text(
                          'GYMPLY.',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          widget.workout.title.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.workout.formattedDate,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Images Section.
                if (_showPhotos && _loadedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: <Widget>[
                        for (int i = 0; i < _loadedImages.length; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: i == 0 ? 0 : 4,
                                right: i == _loadedImages.length - 1 ? 0 : 4,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _loadedImages[i],
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else if (_showPhotos)
                  Container(
                    height: 100,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.dumbbell,
                      size: 40,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),

                // Stats Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _selectedMetrics.map((ShareableMetric metric) {
                    return Column(
                      children: <Widget>[
                        Text(
                          _getMetricValue(metric),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary.withAlpha(200),
                          ),
                        ),
                        Text(
                          '${metric.label}${metric.unit.isNotEmpty ? ' '
                                    '(${metric.unit})' : ''}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),

                // Notes Section
                if (_showNotes && widget.workout.notes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(
                        50,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primaryContainer,
                      ),
                    ),
                    child: Text(
                      widget.workout.notes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // --- CONTROLS ---
        const Text(
          'CUSTOMIZE YOUR POST',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 8),

        // Metric Selector
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ShareableMetric.values.map((ShareableMetric metric) {
              final bool isSelected = _selectedMetrics.contains(metric);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(metric.label),
                  selected: isSelected,
                  onSelected: (_) {
                    _toggleMetric(metric);
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Opt out of sharing images and/or notes.
        SwitchListTile(
          title: const Text('Show Images'),
          secondary: const Icon(LucideIcons.image),
          value: _showPhotos,
          onChanged: (bool val) {
            setState(() => _showPhotos = val);
          },
        ),
        SwitchListTile(
          title: const Text('Show Notes'),
          secondary: const Icon(LucideIcons.notebookPen),
          value: _showNotes,
          onChanged: (bool val) {
            setState(() => _showNotes = val);
          },
        ),

        // Post to GYMPLY Feed Switch (Only if logged in).
        if (canPostToNostr)
          SwitchListTile(
            title: const Text('Post to GYMPLY feed'),
            secondary: const Icon(LucideIcons.rss),
            value: _postToNostr,
            onChanged: _isSharing
                ? null
                : (bool val) {
                    setState(() => _postToNostr = val);
                  },
          ),

        const SizedBox(height: 24),

        // Share Button.
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _isSharing
                ? null
                : () async {
                    setState(() => _isSharing = true);

                    try {
                      // 1. Capture the image bytes.
                      final Uint8List? imageBytes = await shareService
                          .captureImage(_boundaryKey);

                      if (imageBytes == null) {
                        throw Exception('Could not capture workout image.');
                      }

                      // 2. Handle Nostr Posting (if enabled).
                      if (canPostToNostr && _postToNostr) {
                        await nostrService.publishWorkoutNote(
                          imageBytes: imageBytes,
                        );
                        ToastService.showSuccess(
                          title: 'Posted to Feed!',
                          subtitle: 'Your workout is live on GYMPLY.',
                        );
                      }

                      // 3. Trigger standard system share.
                      // We do this last as it might pause the app/modal.
                      await shareService.captureAndShare(
                        _boundaryKey,
                        workoutTitle: widget.workout.title,
                      );

                      // 4. Close the modal.
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } on Object catch (e) {
                      ToastService.showError(
                        title: 'Sharing Failed',
                        subtitle: e.toString(),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isSharing = false);
                      }
                    }
                  },
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.share2),
            label: Text(_isSharing ? 'POSTING...' : 'SHARE WORKOUT'),
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
