import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import 'journal_entry_screen.dart';

/// Journal screen listing all journal entries.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openNewEntry(context),
          ),
        ],
      ),
      body: journalAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildJournalList(entries);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading journal: $e'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewEntry(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _openNewEntry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JournalEntryScreen()),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text(
              'Your journal is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log your cravings, near misses, and milestones\nto understand your triggers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Montserrat',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openNewEntry(context),
              icon: const Icon(Icons.add),
              label: const Text('First Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList(List<JournalEntry> entries) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Group entries by date
    final groupedEntries = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      final dateKey = dateFormat.format(entry.timestamp);
      groupedEntries.putIfAbsent(dateKey, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedEntries.length,
      itemBuilder: (context, index) {
        final dateKey = groupedEntries.keys.elementAt(index);
        final dayEntries = groupedEntries[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...dayEntries.map((entry) => _buildEntryCard(entry, timeFormat)),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(JournalEntry entry, DateFormat timeFormat) {
    Color cardColor;
    switch (entry.eventType) {
      case JournalEventType.craving:
        cardColor = AppColors.secondary.withOpacity(0.1);
        break;
      case JournalEventType.relapse:
        cardColor = AppColors.error.withOpacity(0.08);
        break;
      case JournalEventType.nearMiss:
        cardColor = AppColors.warning.withOpacity(0.08);
        break;
      case JournalEventType.milestone:
        cardColor = AppColors.primary.withOpacity(0.08);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                entry.eventType.icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                entry.eventType.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                timeFormat.format(entry.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          if (entry.triggerType != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flash_on,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Trigger: ${entry.triggerType}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Intensity dots
                Row(
                  children: List.generate(10, (i) {
                    return Container(
                      margin: const EdgeInsets.only(left: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < entry.intensityLevel
                            ? AppColors.accent
                            : AppColors.secondaryLight,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notes!,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Montserrat',
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (entry.interventionUsed != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🛡️ Used: ${entry.interventionUsed}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Montserrat',
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
