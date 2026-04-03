import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus {
  pending('Pending', '⏳'),
  completed('Completed', '✅'),
  failed('Failed', '❌'),
  processing('Processing', '🔄'),
  cancelled('Cancelled', '🚫');

  final String label;
  final String emoji;
  const TransactionStatus(this.label, this.emoji);
}

enum TransactionType {
  credit('Credit', '📥'),
  debit('Debit', '📤');

  final String label;
  final String emoji;
  const TransactionType(this.label, this.emoji);
}

class TransactionModel {
  final String id;
  final String bankAccountId;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String description;
  final DateTime timestamp;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.bankAccountId,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    this.description = '',
    required this.timestamp,
    required this.createdAt,
  });

  double get effectiveAmount {
    if (status == TransactionStatus.failed ||
        status == TransactionStatus.cancelled) {
      return 0.0;
    }
    return type == TransactionType.credit ? amount : -amount;
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      bankAccountId: map['bankAccountId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.credit,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankAccountId': bankAccountId,
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TransactionModel copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    String? description,
  }) {
    return TransactionModel(
      id: id,
      bankAccountId: bankAccountId,
      userId: userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      timestamp: timestamp,
      createdAt: createdAt,
    );
  }
}
