import 'package:gymply/modals/routine_modal.dart';
import 'package:gymply/modals/searchmodal/search_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';

class StartWorkoutModal extends StatelessWidget {
  const StartWorkoutModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Header
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    'START WORKOUT',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'CHOOSE YOUR APPROACH',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: <Widget>[
                  // Option 1: Freestyle
                  Card(
                    child: ListTile(
                      onTap: () async {
                        Navigator.pop(context);

                        // Start total timer
                        await totalTimer.startTimer();

                        // Open exercise search directly
                        if (context.mounted) {
                          await showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return const SearchModal();
                            },
                          );
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHigh,
                        child: Icon(
                          IconUtils.dumbbell,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        'Freestyle',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Start a blank workout for today and log as you go.',
                      ),
                      trailing: Icon(
                        IconUtils.chevronRight,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Option 2: Routines
                  Card(
                    child: ListTile(
                      onTap: () async {
                        Navigator.pop(context);

                        // Open RoutineModal
                        if (context.mounted) {
                          await ModalService.showModal(
                            context: context,
                            child: const RoutineModal(),
                          );
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHigh,
                        child: Icon(
                          IconUtils.list,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        'Routines',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Choose a pre-saved routine template or create a new one.',
                      ),
                      trailing: Icon(
                        IconUtils.chevronRight,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
