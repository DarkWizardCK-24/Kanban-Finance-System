import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/bank_account_model.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/kanban/kanban_column_widget.dart';
import 'add_bank_screen.dart';
import 'add_transaction_screen.dart';

class BankDetailScreen extends StatefulWidget {
  final BankAccountModel account;

  const BankDetailScreen({super.key, required this.account});

  @override
  State<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends State<BankDetailScreen> {
  final _firestoreService = FirestoreService();
  late BankAccountModel _account;
  bool _showCredentials = false;
  bool _showCardNumber = false;
  bool _showCvv = false;
  bool _showAccountNumber = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _listenToAccountUpdates();
  }

  void _listenToAccountUpdates() {
    _firestoreService.getBankAccounts(_account.userId).listen((accounts) {
      if (!mounted) return;
      final updated = accounts.where((a) => a.id == _account.id).firstOrNull;
      if (updated != null) {
        setState(() => _account = updated);
      }
    });
  }

  void _addTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          bankAccountId: _account.id,
          userId: _account.userId,
        ),
      ),
    );
  }

  void _editAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBankScreen(
          userId: _account.userId,
          existingAccount: _account,
        ),
      ),
    );
  }

  void _editTransaction(TransactionModel txn) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          bankAccountId: _account.id,
          userId: _account.userId,
          existingTransaction: txn,
        ),
      ),
    );
  }

  void _deleteTransaction(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Transaction? 🗑️',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${txn.title}" - ${Formatters.currency(txn.amount)}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              _firestoreService.deleteTransaction(txn);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveTransaction(
      TransactionModel txn, TransactionStatus newStatus) async {
    // Map Failed/Cancelled column drop to 'failed' by default
    final updated = txn.copyWith(status: newStatus);
    await _firestoreService.updateTransaction(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved "${txn.title}" to ${newStatus.label}',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.greenAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppColors.greenAccent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_account.category.emoji,
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _account.bankName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
            onPressed: _editAccount,
            tooltip: 'Edit Account',
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
            onPressed: _addTransaction,
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Scrollable top section (header + credentials)
              Flexible(
                flex: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildBankHeader(),
                        _buildCredentialsSection(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              // Kanban Board Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(FontAwesomeIcons.tableCellsLarge,
                          size: 14, color: AppColors.greenAccent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transaction Kanban Board',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Drag cards to move',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Kanban Board - takes remaining space
              Expanded(
                child: _buildKanbanBoard(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
        label: Text('Add Transaction',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildBankHeader() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _firestoreService.getTransactions(_account.id),
      builder: (context, snapshot) {
        double total = 0;
        int txnCount = 0;
        if (snapshot.hasData) {
          txnCount = snapshot.data!.length;
          for (final t in snapshot.data!) {
            total += t.effectiveAmount;
          }
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.greenAccent.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💰 Total Balance',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(total),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                            .animate(target: snapshot.hasData ? 1 : 0)
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.05),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$txnCount txns',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip('🆔 ${_account.id}'),
                  _InfoChip('💳 ${_account.maskedAccountNumber}'),
                  _InfoChip('🏛️ ${_account.ifscCode}'),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05);
      },
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.greenAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenAccent.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _showCredentials = !_showCredentials),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(FontAwesomeIcons.creditCard,
                        size: 14, color: AppColors.greenAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bank Credentials & Card Details',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showCredentials ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const FaIcon(FontAwesomeIcons.chevronDown,
                        size: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding:
                  const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _CredentialRow(
                    icon: FontAwesomeIcons.hashtag,
                    label: 'Account Number',
                    value: _showAccountNumber
                        ? _account.accountNumber
                        : _account.maskedAccountNumber,
                    isHidden: !_showAccountNumber,
                    onToggle: () => setState(
                        () => _showAccountNumber = !_showAccountNumber),
                    onCopy: () => _copyToClipboard(
                        _account.accountNumber, 'Account number'),
                  ),
                  const SizedBox(height: 8),
                  _CredentialRow(
                    icon: FontAwesomeIcons.buildingColumns,
                    label: 'IFSC Code',
                    value: _account.ifscCode,
                    isHidden: false,
                    onCopy: () => _copyToClipboard(
                        _account.ifscCode, 'IFSC code'),
                  ),
                  const SizedBox(height: 8),
                  _CredentialRow(
                    icon: FontAwesomeIcons.creditCard,
                    label: 'Card Number',
                    value: _showCardNumber
                        ? _account.cardNumber
                            .replaceAllMapped(
                                RegExp(r'.{4}'), (m) => '${m[0]} ')
                            .trim()
                        : _account.maskedCardNumber,
                    isHidden: !_showCardNumber,
                    onToggle: () => setState(
                        () => _showCardNumber = !_showCardNumber),
                    onCopy: () => _copyToClipboard(
                        _account.cardNumber, 'Card number'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CredentialRow(
                          icon: FontAwesomeIcons.shieldHalved,
                          label: 'CVV',
                          value: _showCvv ? _account.cvv : '***',
                          isHidden: !_showCvv,
                          onToggle: () =>
                              setState(() => _showCvv = !_showCvv),
                          onCopy: () =>
                              _copyToClipboard(_account.cvv, 'CVV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CredentialRow(
                          icon: FontAwesomeIcons.calendarCheck,
                          label: 'Valid Thru',
                          value: Formatters.monthYear(
                              _account.cardValidity),
                          isHidden: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CredentialRow(
                    icon: FontAwesomeIcons.layerGroup,
                    label: 'Category',
                    value:
                        '${_account.category.emoji} ${_account.category.label}',
                    isHidden: false,
                  ),
                ],
              ),
            ),
            crossFadeState: _showCredentials
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildKanbanBoard() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _firestoreService.getTransactions(_account.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading transactions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const LoadingWidget(message: 'Loading board...');
        }

        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 48))
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to add your first transaction',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final pending = transactions
            .where((t) => t.status == TransactionStatus.pending)
            .toList();
        final processing = transactions
            .where((t) => t.status == TransactionStatus.processing)
            .toList();
        final completed = transactions
            .where((t) => t.status == TransactionStatus.completed)
            .toList();
        final failed = transactions
            .where((t) =>
                t.status == TransactionStatus.failed ||
                t.status == TransactionStatus.cancelled)
            .toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: double.infinity,
                child: KanbanColumnWidget(
                  title: 'Pending',
                  emoji: '⏳',
                  headerColor: AppColors.primaryAmber,
                  backgroundColor: AppColors.kanbanPending,
                  transactions: pending,
                  targetStatus: TransactionStatus.pending,
                  onEditTransaction: _editTransaction,
                  onDeleteTransaction: _deleteTransaction,
                  onTransactionDropped: (txn) =>
                      _moveTransaction(txn, TransactionStatus.pending),
                ),
              ),
              SizedBox(
                height: double.infinity,
                child: KanbanColumnWidget(
                  title: 'Processing',
                  emoji: '🔄',
                  headerColor: AppColors.primaryBlue,
                  backgroundColor: AppColors.kanbanProcessing,
                  transactions: processing,
                  targetStatus: TransactionStatus.processing,
                  onEditTransaction: _editTransaction,
                  onDeleteTransaction: _deleteTransaction,
                  onTransactionDropped: (txn) =>
                      _moveTransaction(txn, TransactionStatus.processing),
                ),
              ),
              SizedBox(
                height: double.infinity,
                child: KanbanColumnWidget(
                  title: 'Completed',
                  emoji: '✅',
                  headerColor: AppColors.success,
                  backgroundColor: AppColors.kanbanCompleted,
                  transactions: completed,
                  targetStatus: TransactionStatus.completed,
                  onEditTransaction: _editTransaction,
                  onDeleteTransaction: _deleteTransaction,
                  onTransactionDropped: (txn) =>
                      _moveTransaction(txn, TransactionStatus.completed),
                ),
              ),
              SizedBox(
                height: double.infinity,
                child: KanbanColumnWidget(
                  title: 'Failed',
                  emoji: '❌',
                  headerColor: AppColors.error,
                  backgroundColor: AppColors.kanbanFailed,
                  transactions: failed,
                  targetStatus: TransactionStatus.failed,
                  onEditTransaction: _editTransaction,
                  onDeleteTransaction: _deleteTransaction,
                  onTransactionDropped: (txn) =>
                      _moveTransaction(txn, TransactionStatus.failed),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHidden;
  final VoidCallback? onToggle;
  final VoidCallback? onCopy;

  const _CredentialRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isHidden,
    this.onToggle,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.greenAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 13, color: AppColors.greenAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: label.contains('Card') ? 1.5 : 0,
                  ),
                ),
              ],
            ),
          ),
          if (onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FaIcon(
                  isHidden
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  size: 13,
                  color: AppColors.greenAccent,
                ),
              ),
            ),
          if (onCopy != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onCopy,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: FaIcon(FontAwesomeIcons.copy,
                    size: 13, color: AppColors.greenAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
