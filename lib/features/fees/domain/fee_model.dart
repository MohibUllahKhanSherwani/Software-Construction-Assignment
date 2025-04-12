class Fee {
  final String schoolId;
  final String schoolName;
  final double amount;
  final String description;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidDate;
  final String? userId;
  final bool adminApproved;

  Fee({
    required this.schoolId,
    required this.schoolName,
    required this.amount,
    required this.description,
    required this.dueDate,
    this.isPaid = false,
    this.paidDate,
    this.userId,
    this.adminApproved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'amount': amount,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
      'userId': userId,
      'adminApproved': adminApproved,
    };
  }

  factory Fee.fromMap(Map<String, dynamic> map) {
    return Fee(
      schoolId: map['schoolId'],
      schoolName: map['schoolName'],
      amount: map['amount'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      isPaid: map['isPaid'] ?? false,
      paidDate:
          map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      userId: map['userId'],
      adminApproved: map['adminApproved'] ?? false,
    );
  }

  Fee copyWith({
    String? schoolId,
    String? schoolName,
    double? amount,
    String? description,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? paidDate,
    String? userId,
    bool? adminApproved,
  }) {
    return Fee(
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      userId: userId ?? this.userId,
      adminApproved: adminApproved ?? this.adminApproved,
    );
  }
}
