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
      if (updated != null) setState(() => _account = updated);
    });
  }

  void _addTransaction() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddTransactionScreen(
        bankAccountId: _account.id,
        userId: _account.userId,
      ),
    ));
  }

  void _editAccount() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddBankScreen(userId: _account.userId, existingAccount: _account),
    ));
  }

  void _editTransaction(TransactionModel txn) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddTransactionScreen(
        bankAccountId: _account.id,
        userId: _account.userId,
        existingTransaction: txn,
      ),
    ));
  }

  void _deleteTransaction(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'Delete "${txn.title}" — ${Formatters.currency(txn.amount)}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _firestoreService.deleteTransaction(txn);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _moveTransaction(TransactionModel txn, TransactionStatus newStatus) async {
    final updated = txn.copyWith(status: newStatus);
    await _firestoreService.updateTransaction(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Moved "${txn.title}" → ${newStatus.label}',
          style: GoogleFonts.inter(color: AppColors.textPrimary)),
      backgroundColor: AppColors.darkCard,
      duration: const Duration(seconds: 2),
    ));
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied',
          style: GoogleFonts.inter(color: AppColors.textPrimary)),
      backgroundColor: AppColors.darkCard,
      duration: const Duration(seconds: 1),
    ));
  }

  List<Color> get _bankColors {
    final bankColors = AppColors.bankGradient(_account.bankName);
    if (bankColors.isNotEmpty) return bankColors;
    switch (_account.category) {
      case AccountCategory.savings:   return AppColors.gradientSavings;
      case AccountCategory.expenses:  return AppColors.gradientExpenses;
      case AccountCategory.fixed:     return AppColors.gradientFixed;
      case AccountCategory.current:   return AppColors.gradientCurrent;
      case AccountCategory.salary:    return AppColors.gradientSalary;
      case AccountCategory.recurring: return AppColors.gradientRecurring;
      case AccountCategory.nri:           return AppColors.gradientNRI;
      case AccountCategory.business:      return AppColors.gradientBusiness;
      case AccountCategory.postalSavings: return AppColors.gradientPostal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_account.category.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _account.bankName,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 15),
            onPressed: _editAccount,
            tooltip: 'Edit Account',
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 17),
            onPressed: _addTransaction,
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Scrollable top section
              Flexible(
                flex: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.52),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        _buildBankHeader(),
                        const SizedBox(height: 12),
                        _buildCredentialsSection(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              // Kanban title bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(FontAwesomeIcons.tableCellsLarge,
                          size: 13, color: AppColors.accentCyan),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transaction Board',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Long-press to drag',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Kanban board
              Expanded(child: _buildKanbanBoard()),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
        label: Text('Add Transaction',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.darkBg)),
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _bankColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _bankColors.first.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Formatters.currency(total),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_account.category.emoji} ${_account.category.label}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              // Account info chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _InfoChip('🆔 ${_account.id}'),
                  _InfoChip('💳 ${_account.maskedAccountNumber}'),
                  if (_account.ifscCode.isNotEmpty)
                    _InfoChip('🏛️ ${_account.ifscCode}'),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.04);
      },
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: FaIcon(
                    _account.hasCard ? FontAwesomeIcons.creditCard : FontAwesomeIcons.bookOpen,
                    size: 13,
                    color: AppColors.accentCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _account.hasCard ? 'Card & Account Credentials' : 'Account Details',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _account.hasCard ? 'Tap 👁 to reveal • Tap 📋 to copy' : 'Tap 📋 to copy',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_account.hasCard)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '📖 Passbook',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.darkDivider),
          const SizedBox(height: 10),

          // Credential rows
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Column(
              children: [
                _CredentialRow(
                  icon: FontAwesomeIcons.hashtag,
                  label: 'Account Number',
                  value: _showAccountNumber
                      ? _account.accountNumber
                      : _account.maskedAccountNumber,
                  isHidden: !_showAccountNumber,
                  onToggle: () => setState(() => _showAccountNumber = !_showAccountNumber),
                  onCopy: () => _copyToClipboard(_account.accountNumber, 'Account number'),
                ),
                const SizedBox(height: 8),
                _CredentialRow(
                  icon: FontAwesomeIcons.buildingColumns,
                  label: 'IFSC Code',
                  value: _account.ifscCode.isEmpty ? '—' : _account.ifscCode,
                  isHidden: false,
                  onCopy: _account.ifscCode.isNotEmpty
                      ? () => _copyToClipboard(_account.ifscCode, 'IFSC code')
                      : null,
                ),

                if (_account.hasCard) ...[
                  const SizedBox(height: 8),
                  _CredentialRow(
                    icon: FontAwesomeIcons.creditCard,
                    label: 'Card Number',
                    value: _showCardNumber
                        ? _account.cardNumber
                            .replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ')
                            .trim()
                        : _account.maskedCardNumber,
                    isHidden: !_showCardNumber,
                    onToggle: () => setState(() => _showCardNumber = !_showCardNumber),
                    onCopy: _account.cardNumber.isNotEmpty
                        ? () => _copyToClipboard(_account.cardNumber, 'Card number')
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CredentialRow(
                          icon: FontAwesomeIcons.shieldHalved,
                          label: 'CVV',
                          value: _showCvv
                              ? (_account.cvv.isEmpty ? '—' : _account.cvv)
                              : '•••',
                          isHidden: !_showCvv,
                          onToggle: _account.cvv.isNotEmpty
                              ? () => setState(() => _showCvv = !_showCvv)
                              : null,
                          onCopy: _account.cvv.isNotEmpty
                              ? () => _copyToClipboard(_account.cvv, 'CVV')
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CredentialRow(
                          icon: FontAwesomeIcons.calendarCheck,
                          label: 'Valid Thru',
                          value: _account.cardValidity != null
                              ? Formatters.monthYear(_account.cardValidity!)
                              : '—',
                          isHidden: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
            child: Text(
              'Error loading transactions',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const LoadingWidget(message: 'Loading board...');
        }

        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📋', style: TextStyle(fontSize: 44))
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text(
                  'No transactions yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap + to add your first transaction',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final pending = transactions.where((t) => t.status == TransactionStatus.pending).toList();
        final processing = transactions.where((t) => t.status == TransactionStatus.processing).toList();
        final completed = transactions.where((t) => t.status == TransactionStatus.completed).toList();
        final failed = transactions.where((t) => t.status == TransactionStatus.failed || t.status == TransactionStatus.cancelled).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: double.infinity,
                child: KanbanColumnWidget(
                  title: 'Pending',
                  emoji: '⏳',
                  headerColor: AppColors.accentAmber,
                  backgroundColor: AppColors.kanbanPending,
                  transactions: pending,
                  targetStatus: TransactionStatus.pending,
                  onEditTransaction: _editTransaction,
                  onDeleteTransaction: _deleteTransaction,
                  onTransactionDropped: (txn) => _moveTransaction(txn, TransactionStatus.pending),
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
                  onTransactionDropped: (txn) => _moveTransaction(txn, TransactionStatus.processing),
                ),
              ),
              SizedBox(
                height: double.infinity,
                child: KanbanColumnWidget(
                  title: 'Completed',
                  emoji: '✅',
                  headerColor: AppColors.accentGreen,
                  backgroundColor: AppColors.kanbanCompleted,
                  transactions: completed,
                  targetStatus: TransactionStatus.completed,
                  onEditTransaction: _editTransaction,
                  onDeleteTransaction: _deleteTransaction,
                  onTransactionDropped: (txn) => _moveTransaction(txn, TransactionStatus.completed),
                ),
              ),
              SizedBox(
                height: double.infinity,
                child: KanbanColumnWidget(
                  title: 'Failed',
                  emoji: '❌',
                  headerColor: AppColors.accentRed,
                  backgroundColor: AppColors.kanbanFailed,
                  transactions: failed,
                  targetStatus: TransactionStatus.failed,
                  onEditTransaction: _editTransaction,
                  onDeleteTransaction: _deleteTransaction,
                  onTransactionDropped: (txn) => _moveTransaction(txn, TransactionStatus.failed),
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
          color: Colors.white.withValues(alpha: 0.85),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 12, color: AppColors.accentCyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: label.contains('Card') || label.contains('IFSC') ? 1.2 : 0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FaIcon(
                  isHidden ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                  size: 12,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
          if (onCopy != null)
            GestureDetector(
              onTap: onCopy,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: FaIcon(FontAwesomeIcons.copy, size: 12, color: AppColors.textHint),
              ),
            ),
        ],
      ),
    );
  }
}