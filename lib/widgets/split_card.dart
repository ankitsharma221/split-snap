import 'package:flutter/material.dart' hide Split;
import 'package:intl/intl.dart';
import '../models/split.dart';

class SplitCard extends StatelessWidget {
  final Split split;
  final VoidCallback onTap;

  const SplitCard({super.key, required this.split, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM • h:mm a').format(split.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _categoryEmoji(split.category),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          split.merchant,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!split.isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('⚠️',
                              style: TextStyle(fontSize: 10)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      date,
                      if (split.locationName != null)
                        '📍 ${split.locationName}',
                    ].join('  '),
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (split.note != null && split.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        split.note!,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${split.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: split.isSettled
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    split.isSettled ? 'Settled' : 'Pending',
                    style: TextStyle(
                        fontSize: 11,
                        color: split.isSettled
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE65100),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String? category) {
    switch (category) {
      case 'Food':
        return '🍕';
      case 'Travel':
        return '🚗';
      case 'Shopping':
        return '🛍️';
      case 'Entertainment':
        return '🎬';
      default:
        return '💸';
    }
  }
}

