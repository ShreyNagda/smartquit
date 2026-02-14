import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';

/// Screen for creating a new journal entry (craving, relapse, near miss, milestone).
class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  JournalEventType _eventType = JournalEventType.craving;
  String? _selectedTrigger;
  int _intensity = 5;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final journalActions = ref.read(journalActionsProvider.notifier);
    bool success;

    switch (_eventType) {
      case JournalEventType.craving:
        success = await journalActions.logCraving(
          triggerType: _selectedTrigger ?? 'Unknown',
          intensity: _intensity,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        break;
      case JournalEventType.nearMiss:
        success = await journalActions.logNearMiss(
          triggerType: _selectedTrigger ?? 'Unknown',
          intensity: _intensity,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        break;
      case JournalEventType.relapse:
        if (_notesController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please describe what happened (required for relapse entries).'),
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }
        success = await journalActions.logRelapse(
          triggerType: _selectedTrigger ?? 'Unknown',
          intensity: _intensity,
          notes: _notesController.text,
        );
        break;
      case JournalEventType.milestone:
        success = await journalActions.logMilestone(
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : 'Personal milestone reached!',
        );
        break;
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry saved! ✍️')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event type selection
            const Text(
              'What happened?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: JournalEventType.values.map((type) {
                final isSelected = _eventType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _eventType = type),
                  labelStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Trigger selection (not for milestones)
            if (_eventType != JournalEventType.milestone) ...[
              const Text(
                'What triggered it?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SmokingTriggers.all.map((trigger) {
                  final isSelected = _selectedTrigger == trigger;
                  return ChoiceChip(
                    label: Text(trigger),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedTrigger = trigger),
                    labelStyle: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Intensity slider
              const Text(
                'How intense was it?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Mild',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      color: AppColors.textLight,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _intensity.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_intensity',
                      activeColor: Color.lerp(
                        AppColors.primary,
                        AppColors.error,
                        (_intensity - 1) / 9,
                      ),
                      onChanged: (v) => setState(() => _intensity = v.round()),
                    ),
                  ),
                  const Text(
                    'Severe',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Center(
                child: Text(
                  '$_intensity / 10',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Notes
            Text(
              _eventType == JournalEventType.relapse
                  ? 'What happened? (Required)'
                  : 'Notes (Optional)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (_eventType == JournalEventType.relapse)
              const Text(
                'Understanding the "why" helps prevent future relapses.',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _eventType == JournalEventType.relapse
                    ? 'Describe what happened and why...'
                    : 'How are you feeling?',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Submit
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _eventType == JournalEventType.relapse
                    ? AppColors.accent
                    : AppColors.primary,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _eventType == JournalEventType.relapse
                          ? 'Log & Learn'
                          : 'Save Entry',
                    ),
            ),

            if (_eventType == JournalEventType.relapse) ...[
              const SizedBox(height: 16),
              const Text(
                '💚 Logging a relapse takes courage.\n'
                'It doesn\'t erase your progress — it helps you grow stronger.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
