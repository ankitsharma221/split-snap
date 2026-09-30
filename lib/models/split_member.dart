
class SplitMember {
  final int? id;
  final int splitId;
  final String name;
  final String? phone;
  final double amountOwed;
  final bool isSettled;

  SplitMember({
    this.id,
    required this.splitId,
    required this.name,
    this.phone,
    required this.amountOwed,
    this.isSettled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'split_id': splitId,
      'name': name,
      'phone': phone,
      'amount_owed': amountOwed,
      'is_settled': isSettled ? 1 : 0,
    };
  }

  factory SplitMember.fromMap(Map<String, dynamic> map) {
    return SplitMember(
      id: map['id'],
      splitId: map['split_id'],
      name: map['name'],
      phone: map['phone'],
      amountOwed: map['amount_owed'],
      isSettled: map['is_settled'] == 1,
    );
  }

  SplitMember copyWith({
    int? id,
    int? splitId,
    String? name,
    String? phone,
    double? amountOwed,
    bool? isSettled,
  }) {
    return SplitMember(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      amountOwed: amountOwed ?? this.amountOwed,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}
