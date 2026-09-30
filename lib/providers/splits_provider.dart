import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split.dart';
import '../models/split_member.dart';
import '../core/database/app_database.dart';

// ─── All Splits ───────────────────────────────────────────────────────────────

final splitsProvider =
    AsyncNotifierProvider<SplitsNotifier, List<Split>>(SplitsNotifier.new);

class SplitsNotifier extends AsyncNotifier<List<Split>> {
  @override
  Future<List<Split>> build() => AppDatabase.instance.getAllSplits();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(AppDatabase.instance.getAllSplits);
  }

  Future<int> addSplit(Split split) async {
    final id = await AppDatabase.instance.insertSplit(split);
    await refresh();
    return id;
  }

  Future<void> updateSplit(Split split) async {
    await AppDatabase.instance.updateSplit(split);
    await refresh();
  }

  Future<void> deleteSplit(int id) async {
    await AppDatabase.instance.deleteSplit(id);
    await refresh();
  }
}

// ─── Incomplete Splits ────────────────────────────────────────────────────────

final incompleteSplitsProvider = FutureProvider<List<Split>>((ref) async {
  // Re-evaluates whenever splitsProvider changes
  ref.watch(splitsProvider);
  return AppDatabase.instance.getIncompleteSplits();
});

// ─── Members for a specific split ─────────────────────────────────────────────

final splitMembersProvider =
    FutureProvider.family<List<SplitMember>, int>((ref, splitId) async {
  return AppDatabase.instance.getMembersForSplit(splitId);
});

// ─── Total owed ───────────────────────────────────────────────────────────────

final totalOwedProvider = FutureProvider<double>((ref) async {
  ref.watch(splitsProvider);
  return AppDatabase.instance.getTotalOwed();
});

// ─── Pending bubble payments (detected but not yet actioned by user) ──────────

final pendingBubblePaymentsProvider =
    StateNotifierProvider<PendingBubbleNotifier, List<Map<String, dynamic>>>(
        PendingBubbleNotifier.new);

class PendingBubbleNotifier
    extends StateNotifier<List<Map<String, dynamic>>> {
  PendingBubbleNotifier(Ref ref) : super([]);

  void add(Map<String, dynamic> payment) {
    state = [...state, payment];
  }

  void remove(int splitId) {
    state = state.where((p) => p['split_id'] != splitId).toList();
  }

  void clear() => state = [];
}
