import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/split.dart';
import '../../providers/splits_provider.dart';
import '../split_detail/split_detail_screen.dart';
import '../add_edit_split/add_edit_split_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/split_card.dart';
import '../../widgets/summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitsAsync = ref.watch(splitsProvider);
    final totalOwedAsync = ref.watch(totalOwedProvider);
    final incompleteAsync = ref.watch(incompleteSplitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Row(
          children: [
            Text('💸', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('SplitSnap',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(splitsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // ── Summary card ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: totalOwedAsync.when(
                data: (total) => SummaryCard(totalOwed: total),
                loading: () => const SummaryCard(totalOwed: 0),
                error: (_, __) => const SummaryCard(totalOwed: 0),
              ),
            ),

            // ── Incomplete splits banner ───────────────────────────────────
            incompleteAsync.when(
              data: (incomplete) {
                if (incomplete.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: _IncompletesBanner(count: incomplete.length, splits: incomplete),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Section header ─────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('All Splits',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
              ),
            ),

            // ── Splits list ────────────────────────────────────────────────
            splitsAsync.when(
              data: (splits) {
                if (splits.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyState());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => SplitCard(
                      split: splits[i],
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              SplitDetailScreen(splitId: splits[i].id!),
                        ),
                      ),
                    ),
                    childCount: splits.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) =>
                  SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),

      // ── FAB: Manual add ───────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditSplitScreen()),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Split',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Incomplete banner ──────────────────────────────────────────────────────────

class _IncompletesBanner extends StatelessWidget {
  final int count;
  final List<Split> splits;
  const _IncompletesBanner({required this.count, required this.splits});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count split${count > 1 ? 's' : ''} need your attention',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Text('Location & time saved. Add people & note.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A6500))),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (splits.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SplitDetailScreen(splitId: splits.first.id!),
                  ),
                );
              }
            },
            child: const Text('Fill',
                style: TextStyle(
                    color: Color(0xFF856404), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💸', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No splits yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('Make a UPI payment and SplitSnap\nwill detect it automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}

