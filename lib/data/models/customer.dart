/// Model khách hàng
class Customer {
  final int? id;
  final String code;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxCode;
  final String? bankAccount;
  final String? bankName;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.code,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.taxCode,
    this.bankAccount,
    this.bankName,
    this.note,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Customer copyWith({
    int? id,
    String? code,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? taxCode,
    String? bankAccount,
    String? bankName,
    String? note,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxCode: taxCode ?? this.taxCode,
      bankAccount: bankAccount ?? this.bankAccount,
      bankName: bankName ?? this.bankName,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'tax_code': taxCode,
      'bank_account': bankAccount,
      'bank_name': bankName,
      'note': note,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      taxCode: map['tax_code'] as String?,
      bankAccount: map['bank_account'] as String?,
      bankName: map['bank_name'] as String?,
      note: map['note'] as String?,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
