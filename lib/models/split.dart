class Split {
  final int? id;
  final double amount;
  final String merchant;
  final String? bankName;
  final String? upiRef;
  final String? note;
  final String? category;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? wifiName;
  final String? photoPath;
  final bool isComplete;
  final bool isSettled;
  final DateTime createdAt;

  Split({
    this.id,
    required this.amount,
    required this.merchant,
    this.bankName,
    this.upiRef,
    this.note,
    this.category,
    this.latitude,
    this.longitude,
    this.locationName,
    this.wifiName,
    this.photoPath,
    this.isComplete = false,
    this.isSettled = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'bank_name': bankName,
      'upi_ref': upiRef,
      'note': note,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'wifi_name': wifiName,
      'photo_path': photoPath,
      'is_complete': isComplete ? 1 : 0,
      'is_settled': isSettled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Split.fromMap(Map<String, dynamic> map) {
    return Split(
      id: map['id'],
      amount: map['amount'],
      merchant: map['merchant'],
      bankName: map['bank_name'],
      upiRef: map['upi_ref'],
      note: map['note'],
      category: map['category'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['location_name'],
      wifiName: map['wifi_name'],
      photoPath: map['photo_path'],
      isComplete: map['is_complete'] == 1,
      isSettled: map['is_settled'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Split copyWith({
    int? id,
    double? amount,
    String? merchant,
    String? bankName,
    String? upiRef,
    String? note,
    String? category,
    double? latitude,
    double? longitude,
    String? locationName,
    String? wifiName,
    String? photoPath,
    bool? isComplete,
    bool? isSettled,
    DateTime? createdAt,
  }) {
    return Split(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      bankName: bankName ?? this.bankName,
      upiRef: upiRef ?? this.upiRef,
      note: note ?? this.note,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      wifiName: wifiName ?? this.wifiName,
      photoPath: photoPath ?? this.photoPath,
      isComplete: isComplete ?? this.isComplete,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
