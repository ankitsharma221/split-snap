import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/split.dart';
import '../../models/split_member.dart';
import '../../providers/splits_provider.dart';
import '../../core/database/app_database.dart';
import '../add_edit_split/add_edit_split_screen.dart';
import '../../widgets/info_row.dart';

class SplitDetailScreen extends ConsumerWidget {
  final int splitId;
  const SplitDetailScreen({super.key, required this.splitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitAsync = ref.watch(splitsProvider).whenData(
      (splits) => splits.firstWhere((s) => s.id == splitId, orElse: () => splits.first),
    );
    final membersAsync = ref.watch(splitMembersProvider(splitId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: const BackButton(color: Colors.white),
        title: const Text('Split Detail',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditSplitScreen(splitId: splitId)),
            ),
          ),
        ],
      ),
      body: splitAsync.when(
        data: (split) => _Body(split: split, membersAsync: membersAsync, ref: ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Split split;
  final AsyncValue<List<SplitMember>> membersAsync;
  final WidgetRef ref;

  const _Body(
      {required this.split,
      required this.membersAsync,
      required this.ref});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, d MMM yyyy • h:mm a').format(split.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Amount card ──────────────────────────────────────────────────
          _AmountCard(split: split),
          const SizedBox(height: 16),

          // ── Context card ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Payment Context',
            children: [
              InfoRow(icon: '🕐', label: 'Time', value: dateStr),
              if (split.locationName != null)
                InfoRow(icon: '📍', label: 'Location', value: split.locationName!),
              if (split.wifiName != null)
                InfoRow(icon: '📶', label: 'WiFi', value: split.wifiName!),
              if (split.bankName != null)
                InfoRow(icon: '🏦', label: 'Bank', value: split.bankName!),
              if (split.upiRef != null)
                InfoRow(icon: '🔖', label: 'UPI Ref', value: split.upiRef!),
              if (split.note != null && split.note!.isNotEmpty)
                InfoRow(icon: '📝', label: 'Note', value: split.note!),
              if (split.category != null)
                InfoRow(icon: '🏷️', label: 'Category', value: split.category!),
            ],
          ),

          // ── Photo ────────────────────────────────────────────────────────
          if (split.photoPath != null) ...[
            const SizedBox(height: 16),
            _PhotoCard(photoPath: split.photoPath!),
          ],

          const SizedBox(height: 16),

          // ── People ───────────────────────────────────────────────────────
          membersAsync.when(
            data: (members) => _PeopleCard(
                members: members, split: split, ref: ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading members: $e'),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Amount card ────────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final Split split;
  const _AmountCard({required this.split});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${split.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
              if (!split.isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('⚠️ Incomplete',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A6500))),
                ),
              if (split.isSettled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✅ Settled',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(split.merchant,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
        ],
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

// ── Photo card ─────────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final String photoPath;
  const _PhotoCard({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Image.asset(photoPath, fit: BoxFit.contain),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          photoPath,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 160,
            color: Colors.grey[200],
            child: const Center(child: Text('📸 Photo attached')),
          ),
        ),
      ),
    );
  }
}

// ── People card ────────────────────────────────────────────────────────────────

class _PeopleCard extends StatelessWidget {
  final List<SplitMember> members;
  final Split split;
  final WidgetRef ref;
  const _PeopleCard(
      {required this.members, required this.split, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Text('👥', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text('No people added yet',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Split with',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ...members.map((m) => _MemberRow(member: m, ref: ref)),
          const SizedBox(height: 12),
          if (members.any((m) => !m.isSettled))
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _markAllSettled(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Mark All Settled ✅',
                    style: TextStyle(color: Color(0xFF4CAF50))),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markAllSettled(BuildContext context) async {
    final db = AppDatabase.instance;
    for (final m in members) {
      await db.updateMember(m.copyWith(isSettled: true));
    }
    if (split.id != null) {
      await db.updateSplit(split.copyWith(isSettled: true));
    }
    await ref.read(splitsProvider.notifier).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All settled!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }
}

class _MemberRow extends StatelessWidget {
  final SplitMember member;
  final WidgetRef ref;
  const _MemberRow({required this.member, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('₹${member.amountOwed.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          if (member.isSettled)
            const Chip(
              label: Text('Settled', style: TextStyle(fontSize: 11)),
              backgroundColor: Color(0xFFE8F5E9),
              side: BorderSide.none,
            )
          else if (member.phone != null && member.phone!.isNotEmpty)
            TextButton.icon(
              onPressed: () => _sendWhatsApp(context, member),
              icon: const Text('📲', style: TextStyle(fontSize: 14)),
              label: Text('Remind',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsApp(BuildContext context, SplitMember member) async {
    final phone = member.phone!.replaceAll(RegExp(r'\D'), '');
    final number = phone.startsWith('91') ? phone : '91$phone';
    final msg = Uri.encodeComponent(
        'Hi ${member.name}, you owe me ₹${member.amountOwed.toStringAsFixed(0)}. Please settle when free 😊');
    final url = Uri.parse('https://wa.me/$number?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp not found on this device')),
        );
      }
    }
  }
}

