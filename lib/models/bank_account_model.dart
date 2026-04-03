import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountCategory {
  savings('Savings', '💰'),
  expenses('Expenses', '💳'),
  fixed('Fixed Deposit', '🏦'),
  current('Current', '🔄'),
  salary('Salary', '💵'),
  recurring('Recurring Deposit', '📅'),
  nri('NRI', '🌍'),
  business('Business', '🏢'),
  postalSavings('Postal Savings', '📮');

  final String label;
  final String emoji;
  const AccountCategory(this.label, this.emoji);
}

class BankAccountModel {
  final String id;
  final String userId;
  final String bankName;
  final AccountCategory category;
  final String accountNumber;
  final String ifscCode;
  final String cardNumber;   // empty string for no-card banks
  final String cvv;          // empty string for no-card banks
  final DateTime? cardValidity; // null for no-card banks
  final bool hasCard;           // false for passbook/account-only banks
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BankAccountModel({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.category,
    required this.accountNumber,
    required this.ifscCode,
    this.cardNumber = '',
    this.cvv = '',
    this.cardValidity,
    this.hasCard = true,
    this.totalAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True only when the account has full card credentials stored.
  bool get hasCardCredentials =>
      hasCard && cardNumber.isNotEmpty && cvv.isNotEmpty && cardValidity != null;

  String get maskedCardNumber {
    if (!hasCard || cardNumber.length < 4) return '•••• •••• •••• ••••';
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String get maskedAccountNumber {
    if (accountNumber.length < 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  factory BankAccountModel.fromMap(Map<String, dynamic> map) {
    return BankAccountModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      bankName: map['bankName'] ?? '',
      category: AccountCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AccountCategory.savings,
      ),
      accountNumber: map['accountNumber'] ?? '',
      ifscCode: map['ifscCode'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      cvv: map['cvv'] ?? '',
      cardValidity: (map['cardValidity'] as Timestamp?)?.toDate(),
      // Existing docs without hasCard field default to true
      hasCard: map['hasCard'] as bool? ?? (map['cardNumber'] != null && (map['cardNumber'] as String).isNotEmpty),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bankName': bankName,
      'category': category.name,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'cardNumber': cardNumber,
      'cvv': cvv,
      'cardValidity': cardValidity != null ? Timestamp.fromDate(cardValidity!) : null,
      'hasCard': hasCard,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BankAccountModel copyWith({
    String? bankName,
    AccountCategory? category,
    String? accountNumber,
    String? ifscCode,
    String? cardNumber,
    String? cvv,
    DateTime? cardValidity,
    bool? hasCard,
    double? totalAmount,
  }) {
    return BankAccountModel(
      id: id,
      userId: userId,
      bankName: bankName ?? this.bankName,
      category: category ?? this.category,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      cardNumber: cardNumber ?? this.cardNumber,
      cvv: cvv ?? this.cvv,
      cardValidity: cardValidity ?? this.cardValidity,
      hasCard: hasCard ?? this.hasCard,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}