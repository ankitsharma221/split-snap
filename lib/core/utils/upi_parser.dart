import '../../models/detected_payment.dart';

/// Parses UPI debit SMS messages from all major Indian banks.
/// Returns a [DetectedPayment] if the SMS is a UPI debit, otherwise null.
class UpiParser {
  // Matches: Rs.500, Rs 500, INR 500, INR500, ₹500, ₹ 500.00
  static final _amountRegex = RegExp(
    r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Matches: "debited", "paid", "sent", "transferred" — indicates money out
  static final _debitKeywords = RegExp(
    r'\b(debited|paid|sent|transferred|deducted|withdrawn)\b',
    caseSensitive: false,
  );

  // Matches: "credited", "received", "added" — money in, we ignore these
  static final _creditKeywords = RegExp(
    r'\b(credited|received|added|deposited)\b',
    caseSensitive: false,
  );

  // Extract merchant / VPA name after common UPI SMS patterns
  static final _merchantPatterns = [
    // "to MERCHANT" or "to VPA merchant@upi"
    RegExp(r'\bto\s+([A-Za-z0-9 _&.\-]+?)(?:\s+(?:via|on|ref|upi|vpa|@|\.|,|Rs|INR|for)|\s*$)',
        caseSensitive: false),
    // "paid at MERCHANT"
    RegExp(r'\bpaid\s+at\s+([A-Za-z0-9 _&.\-]+?)(?:\s+(?:via|on|ref|Rs|INR)|\s*$)',
        caseSensitive: false),
    // "towards MERCHANT"
    RegExp(r'\btowards\s+([A-Za-z0-9 _&.\-]+?)(?:\s+(?:via|on|ref|Rs|INR)|\s*$)',
        caseSensitive: false),
  ];

  // UPI Ref No
  static final _upiRefRegex = RegExp(
    r'\b(?:upi\s*ref(?:\.?\s*no\.?)?|ref(?:erence)?\s*(?:no\.?)?)\s*:?\s*([0-9]{9,20})\b',
    caseSensitive: false,
  );

  // Bank sender IDs → bank name mapping
  static const _bankSenderMap = {
    'SBIINB': 'SBI',
    'SBIPSG': 'SBI',
    'HDFCBK': 'HDFC',
    'HDFCBN': 'HDFC',
    'ICICIB': 'ICICI',
    'ICICIT': 'ICICI',
    'AXISBK': 'Axis',
    'AXISBN': 'Axis',
    'KOTAKB': 'Kotak',
    'INDBNK': 'Indian Bank',
    'PNBSMS': 'PNB',
    'BOIIND': 'Bank of India',
    'CANBNK': 'Canara',
    'YESBNK': 'Yes Bank',
    'IDBIBK': 'IDBI',
    'PAYTMB': 'Paytm',
    'PHONEPE': 'PhonePe',
    'GPAY': 'Google Pay',
  };

  /// Returns [DetectedPayment] if SMS is a UPI debit, null otherwise.
  static DetectedPayment? parse(String smsBody, String sender) {
    // Skip credits
    if (_creditKeywords.hasMatch(smsBody) &&
        !_debitKeywords.hasMatch(smsBody)) {
      return null;
    }

    // Must contain UPI keyword
    if (!smsBody.toLowerCase().contains('upi')) return null;

    // Must be a debit
    if (!_debitKeywords.hasMatch(smsBody)) return null;

    // Extract amount
    final amountMatch = _amountRegex.firstMatch(smsBody);
    if (amountMatch == null) return null;
    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // Extract merchant
    String merchant = 'Unknown';
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        final raw = match.group(1)?.trim() ?? '';
        if (raw.isNotEmpty && raw.length > 1) {
          merchant = _cleanMerchant(raw);
          break;
        }
      }
    }

    // Extract UPI ref
    final refMatch = _upiRefRegex.firstMatch(smsBody);
    final upiRef = refMatch?.group(1);

    // Extract bank name from sender
    final senderUpper = sender.toUpperCase();
    String? bankName;
    for (final entry in _bankSenderMap.entries) {
      if (senderUpper.contains(entry.key)) {
        bankName = entry.value;
        break;
      }
    }

    return DetectedPayment(
      amount: amount,
      merchant: merchant,
      bankName: bankName,
      upiRef: upiRef,
      detectedAt: DateTime.now(),
      rawSms: smsBody,
    );
  }

  static String _cleanMerchant(String raw) {
    // Remove trailing noise words
    final noiseWords = RegExp(
        r'\b(upi|vpa|ref|via|on|for|by|from|your|account|ac|a\/c|no|number)\b.*$',
        caseSensitive: false);
    var cleaned = raw.replaceAll(noiseWords, '').trim();

    // Capitalise first letter of each word
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
