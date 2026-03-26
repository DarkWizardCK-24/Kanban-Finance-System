import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/bank_account_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../bank/add_bank_screen.dart';
import '../bank/add_transaction_screen.dart';
import '../bank/bank_detail_screen.dart';

class AccountKanbanScreen extends StatefulWidget {
  final UserModel user;
  final FirestoreService firestoreService;

  const AccountKanbanScreen({
    super.key,
    required this.user,
    required this.firestoreService,
  });

  @override
  State<AccountKanbanScreen> createState() => _AccountKanbanScreenState();
}

class _AccountKanbanScreenState extends State<AccountKanbanScreen> {
  Future<void> _moveTransactionToAccount(
      TransactionModel txn, BankAccountModel targetAccount) async {
    if (txn.bankAccountId == targetAccount.id) return;
    await widget.firestoreService
        .moveTransactionToAccount(txn, targetAccount.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved "${txn.title}" to ${targetAccount.bankName}',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.greenAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addTransaction(BankAccountModel account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          bankAccountId: account.id,
          userId: widget.user.uid,
        ),
      ),
    );
  }

  void _editTransaction(TransactionModel txn, BankAccountModel account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          bankAccountId: account.id,
          userId: widget.user.uid,
          existingTransaction: txn,
        ),
      ),
    );
  }

  void _deleteTransaction(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Transaction? 🗑️',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${txn.title}" - ${Formatters.currency(txn.amount)}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              widget.firestoreService.deleteTransaction(txn);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BankAccountModel>>(
      stream: widget.firestoreService.getBankAccounts(widget.user.uid),
      builder: (context, accountSnapshot) {
        if (accountSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😕', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Error loading accounts',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          );
        }
        if (!accountSnapshot.hasData) {
          return const LoadingWidget(message: 'Loading kanban board...');
        }

        final accounts = accountSnapshot.data!;
        if (accounts.isEmpty) {
          return EmptyStateWidget(
            emoji: '📋',
            title: 'No Bank Accounts',
            subtitle: 'Add bank accounts to see them on the kanban board!',
            actionLabel: 'Add Bank Account',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddBankScreen(userId: widget.user.uid),
              ),
            ),
          );
        }

        return StreamBuilder<List<TransactionModel>>(
          stream:
              widget.firestoreService.getAllTransactions(widget.user.uid),
          builder: (context, txnSnapshot) {
            final allTransactions = txnSnapshot.data ?? [];

            // Group transactions by bankAccountId
            final txnByAccount = <String, List<TransactionModel>>{};
            for (final txn in allTransactions) {
              txnByAccount
                  .putIfAbsent(txn.bankAccountId, () => [])
                  .add(txn);
            }

            // Calculate total
            final totalBalance = accounts.fold<double>(
                0, (sum, a) => sum + a.totalAmount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                            FontAwesomeIcons.tableCellsLarge,
                            size: 16,
                            color: AppColors.greenAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Kanban Board',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${accounts.length} accounts  |  ${allTransactions.length} transactions  |  ${Formatters.compactCurrency(totalBalance)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.greenAccentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Drag txns to move',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenAccentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                // Kanban Board - each column is a bank account
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: accounts.map((account) {
                        final txns = txnByAccount[account.id] ?? [];
                        return SizedBox(
                          height: double.infinity,
                          child: _BankAccountColumn(
                            account: account,
                            transactions: txns,
                            onTransactionDropped: (txn) =>
                                _moveTransactionToAccount(txn, account),
                            onAddTransaction: () =>
                                _addTransaction(account),
                            onEditTransaction: (txn) =>
                                _editTransaction(txn, account),
                            onDeleteTransaction: _deleteTransaction,
                            onTapHeader: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    BankDetailScreen(account: account),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ==================== BANK ACCOUNT COLUMN ====================

List<Color> _gradientForCategory(AccountCategory category) {
  switch (category) {
    case AccountCategory.savings:
      return [const Color(0xFF43A047), const Color(0xFF2E7D32)];
    case AccountCategory.expenses:
      return [const Color(0xFFFF8F00), const Color(0xFFF57C00)];
    case AccountCategory.fixed:
      return [const Color(0xFF00897B), const Color(0xFF00695C)];
    case AccountCategory.current:
      return [const Color(0xFF0288D1), const Color(0xFF01579B)];
    case AccountCategory.salary:
      return [const Color(0xFF558B2F), const Color(0xFF33691E)];
    case AccountCategory.recurring:
      return [const Color(0xFF00ACC1), const Color(0xFF00838F)];
    case AccountCategory.nri:
      return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
    case AccountCategory.business:
      return [const Color(0xFF4E342E), const Color(0xFF3E2723)];
  }
}

class _BankAccountColumn extends StatelessWidget {
  final BankAccountModel account;
  final List<TransactionModel> transactions;
  final void Function(TransactionModel) onTransactionDropped;
  final VoidCallback onAddTransaction;
  final void Function(TransactionModel) onEditTransaction;
  final void Function(TransactionModel) onDeleteTransaction;
  final VoidCallback onTapHeader;

  const _BankAccountColumn({
    required this.account,
    required this.transactions,
    required this.onTransactionDropped,
    required this.onAddTransaction,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.onTapHeader,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _gradientForCategory(account.category);
    final columnColor = colors.first;

    // Live balance from transactions
    double liveBalance = 0;
    for (final t in transactions) {
      liveBalance += t.effectiveAmount;
    }

    final creditCount =
        transactions.where((t) => t.type == TransactionType.credit).length;
    final debitCount =
        transactions.where((t) => t.type == TransactionType.debit).length;

    return DragTarget<TransactionModel>(
      onWillAcceptWithDetails: (details) {
        return details.data.bankAccountId != account.id;
      },
      onAcceptWithDetails: (details) {
        onTransactionDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovering
                ? columnColor.withValues(alpha: 0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? columnColor : AppColors.divider,
              width: isHovering ? 2.5 : 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: columnColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // ---- Column Header: Bank Account Card ----
              GestureDetector(
                onTap: onTapHeader,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.buildingColumns,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              account.bankName,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${account.category.emoji} ${account.category.label}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        account.maskedCardNumber,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance',
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                Formatters.currency(liveBalance),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text('📥 $creditCount',
                                      style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Text('📤 $debitCount',
                                      style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${transactions.length} transactions',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Add Transaction Button ----
              GestureDetector(
                onTap: onAddTransaction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  decoration: BoxDecoration(
                    color: columnColor.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.plus,
                          size: 11, color: columnColor),
                      const SizedBox(width: 6),
                      Text(
                        'Add Transaction',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: columnColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Drop Hint ----
              if (isHovering)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: columnColor.withValues(alpha: 0.06),
                  child: Center(
                    child: Text(
                      'Drop here to move to ${account.bankName}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: columnColor,
                      ),
                    ),
                  ),
                ),

              // ---- Transaction Cards ----
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isHovering ? '📥' : '📋',
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isHovering
                                    ? 'Drop here!'
                                    : 'No transactions yet',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isHovering
                                      ? columnColor
                                      : AppColors.textHint,
                                  fontWeight: isHovering
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final txn = transactions[index];
                          return _DraggableTxnCard(
                            txn: txn,
                            index: index,
                            onEdit: () => onEditTransaction(txn),
                            onDelete: () => onDeleteTransaction(txn),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== DRAGGABLE TRANSACTION CARD ====================

class _DraggableTxnCard extends StatelessWidget {
  final TransactionModel txn;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DraggableTxnCard({
    required this.txn,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<TransactionModel>(
      data: txn,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        shadowColor: AppColors.greenAccent.withValues(alpha: 0.4),
        child: SizedBox(
          width: 270,
          child: _TxnCardContent(txn: txn, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _TxnCardContent(txn: txn),
      ),
      child: _TxnCardContent(
        txn: txn,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    )
        .animate()
        .fadeIn(
            duration: 250.ms, delay: Duration(milliseconds: index * 60))
        .slideY(begin: 0.04);
  }
}

// ==================== TRANSACTION CARD CONTENT ====================

class _TxnCardContent extends StatelessWidget {
  final TransactionModel txn;
  final bool isDragging;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TxnCardContent({
    required this.txn,
    this.isDragging = false,
    this.onEdit,
    this.onDelete,
  });

  Color get _statusColor {
    switch (txn.status) {
      case TransactionStatus.pending:
        return AppColors.primaryAmber;
      case TransactionStatus.processing:
        return AppColors.primaryBlue;
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.failed:
        return AppColors.error;
      case TransactionStatus.cancelled:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.type == TransactionType.credit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDragging ? AppColors.greenAccentLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDragging ? AppColors.greenAccent : AppColors.divider,
          width: isDragging ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? AppColors.greenAccent.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isDragging ? 14 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    txn.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: FaIcon(FontAwesomeIcons.penToSquare,
                          size: 12, color: AppColors.textHint),
                    ),
                  ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: FaIcon(FontAwesomeIcons.trash,
                          size: 12, color: AppColors.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Amount chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCredit
                    ? AppColors.lightGreen
                    : AppColors.lightAmber,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(txn.type.emoji,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${isCredit ? '+' : '-'} ${Formatters.currency(txn.amount)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isCredit
                          ? AppColors.greenAccentDark
                          : AppColors.primaryAmber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Status + time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(txn.status.emoji,
                          style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Text(
                        txn.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.timeAgo(txn.timestamp),
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),

            // Description
            if (txn.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                txn.description,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
