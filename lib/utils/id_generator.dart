import 'package:cloud_firestore/cloud_firestore.dart';

class IdGenerator {
  static Future<String> generateUserId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'USER0001';
    }

    final lastId = snapshot.docs.first.data()['id'] as String? ?? 'USER0000';
    final number = int.parse(lastId.replaceAll('USER', ''));
    return 'USER${(number + 1).toString().padLeft(4, '0')}';
  }

  static Future<String> generateBankId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bank_accounts')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'BANK0001';
    }

    final lastId = snapshot.docs.first.data()['id'] as String? ?? 'BANK0000';
    final number = int.parse(lastId.replaceAll('BANK', ''));
    return 'BANK${(number + 1).toString().padLeft(4, '0')}';
  }

  static Future<String> generateTransactionId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'TXN0001';
    }

    final lastId = snapshot.docs.first.data()['id'] as String? ?? 'TXN0000';
    final number = int.parse(lastId.replaceAll('TXN', ''));
    return 'TXN${(number + 1).toString().padLeft(4, '0')}';
  }
}
