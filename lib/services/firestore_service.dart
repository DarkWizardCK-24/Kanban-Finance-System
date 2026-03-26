import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bank_account_model.dart';
import '../models/transaction_model.dart';
import '../utils/id_generator.dart';
import '../utils/wealth_calculator.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== BANK ACCOUNTS ====================

  Stream<List<BankAccountModel>> getBankAccounts(String userId) {
    return _firestore
        .collection('bank_accounts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BankAccountModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<BankAccountModel> getBankAccount(String docId) async {
    final doc = await _firestore.collection('bank_accounts').doc(docId).get();
    return BankAccountModel.fromMap(doc.data()!);
  }

  Future<BankAccountModel> createBankAccount({
    required String userId,
    required String bankName,
    required AccountCategory category,
    required String accountNumber,
    required String ifscCode,
    required String cardNumber,
    required String cvv,
    required DateTime cardValidity,
  }) async {
    final bankId = await IdGenerator.generateBankId();
    final now = DateTime.now();

    final account = BankAccountModel(
      id: bankId,
      userId: userId,
      bankName: bankName,
      category: category,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      cardNumber: cardNumber,
      cvv: cvv,
      cardValidity: cardValidity,
      totalAmount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('bank_accounts')
        .doc(bankId)
        .set(account.toMap());

    return account;
  }

  Future<void> updateBankAccount(BankAccountModel account) async {
    await _firestore
        .collection('bank_accounts')
        .doc(account.id)
        .update(account.copyWith().toMap());
  }

  Future<void> deleteBankAccount(String bankId) async {
    // Delete all transactions for this bank account
    final transactions = await _firestore
        .collection('transactions')
        .where('bankAccountId', isEqualTo: bankId)
        .get();

    final batch = _firestore.batch();
    for (final doc in transactions.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('bank_accounts').doc(bankId));
    await batch.commit();
  }

  // ==================== TRANSACTIONS ====================

  Stream<List<TransactionModel>> getTransactions(String bankAccountId) {
    return _firestore
        .collection('transactions')
        .where('bankAccountId', isEqualTo: bankAccountId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<TransactionModel>> getAllTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<TransactionModel> createTransaction({
    required String bankAccountId,
    required String userId,
    required String title,
    required double amount,
    required TransactionType type,
    required TransactionStatus status,
    String description = '',
  }) async {
    final txnId = await IdGenerator.generateTransactionId();
    final now = DateTime.now();

    final transaction = TransactionModel(
      id: txnId,
      bankAccountId: bankAccountId,
      userId: userId,
      title: title,
      amount: amount,
      type: type,
      status: status,
      description: description,
      timestamp: now,
      createdAt: now,
    );

    await _firestore
        .collection('transactions')
        .doc(txnId)
        .set(transaction.toMap());

    // Update bank account total
    await _updateBankAccountTotal(bankAccountId);

    return transaction;
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());

    // Recalculate bank total
    await _updateBankAccountTotal(transaction.bankAccountId);
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').doc(transaction.id).delete();
    await _updateBankAccountTotal(transaction.bankAccountId);
  }

  Future<void> moveTransactionToAccount(
      TransactionModel transaction, String newBankAccountId) async {
    final oldBankAccountId = transaction.bankAccountId;
    await _firestore.collection('transactions').doc(transaction.id).update({
      'bankAccountId': newBankAccountId,
    });
    // Recalculate both account totals
    await _updateBankAccountTotal(oldBankAccountId);
    await _updateBankAccountTotal(newBankAccountId);
  }

  Future<void> _updateBankAccountTotal(String bankAccountId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('bankAccountId', isEqualTo: bankAccountId)
        .get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();

    final total = WealthCalculator.calculateAccountTotal(transactions);

    await _firestore.collection('bank_accounts').doc(bankAccountId).update({
      'totalAmount': total,
      'updatedAt': Timestamp.now(),
    });
  }

  // ==================== WEALTH ====================

  Future<WealthSummary> getWealthSummary(String userId) async {
    final accountsSnapshot = await _firestore
        .collection('bank_accounts')
        .where('userId', isEqualTo: userId)
        .get();

    final accounts = accountsSnapshot.docs
        .map((doc) => BankAccountModel.fromMap(doc.data()))
        .toList();

    final txnSnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = txnSnapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();

    return WealthCalculator.calculateWealth(
      accounts: accounts,
      transactions: transactions,
    );
  }
}
