import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/splits_provider.dart';
import '../add_edit_split/add_edit_split_screen.dart';

/// Bottom sheet popup shown when bubble is tapped.
/// Pre-fills amount + merchant + location from the saved split.
class SplitPopup extends ConsumerWidget {
  final int splitId;
  final double amount;
  final String merchant;

  const SplitPopup({
    super.key,
    required this.splitId,
    required this.amount,
    required this.merchant,
  });

  static Future<void> show(
    BuildContext context, {
    required int splitId,
    required double amount,
    required String merchant,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitPopup(
        splitId: splitId,
        amount: amount,
        merchant: merchant,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('💳', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E)),
                    ),
                    Text(
                      merchant,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Dismiss X
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Info row
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF4CAF50)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Location & time captured automatically',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Text('⚡', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Quick Save  (add details later)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () => _quickSave(context, ref),
            ),
          ),

          const SizedBox(height: 10),

          // Full edit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF1A1A2E), size: 18),
              label: const Text(
                'Add People & Note now',
                style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () => _openFullEdit(context),
            ),
          ),

          const SizedBox(height: 10),

          // Not a split
          TextButton(
            onPressed: () async {
              await ref.read(splitsProvider.notifier).deleteSplit(splitId);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Not a split — dismiss',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _quickSave(BuildContext context, WidgetRef ref) async {
    // Already saved as Incomplete — just pop. User fills later.
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '💾 ₹${amount.toStringAsFixed(0)} saved — add details when free'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
    await ref.read(splitsProvider.notifier).refresh();
  }

  void _openFullEdit(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSplitScreen(splitId: splitId),
      ),
    );
  }
}


