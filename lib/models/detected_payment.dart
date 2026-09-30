class DetectedPayment {
  final double amount;
  final String merchant;
  final String? bankName;
  final String? upiRef;
  final DateTime detectedAt;
  final String rawSms;

  DetectedPayment({
    required this.amount,
    required this.merchant,
    this.bankName,
    this.upiRef,
    required this.detectedAt,
    required this.rawSms,
  });
}
