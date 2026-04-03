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
    await widget.firestoreService.moveTransactionToAccount(txn, targetAccount.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Moved "${txn.title}" → ${targetAccount.bankName}',
        style: GoogleFonts.inter(color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.darkCard,
      duration: const Duration(seconds: 2),
    ));
  }

  void _addTransaction(BankAccountModel account) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddTransactionScreen(
        bankAccountId: account.id,
        userId: widget.user.uid,
      ),
    ));
  }

  void _editTransaction(TransactionModel txn, BankAccountModel account) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddTransactionScreen(
        bankAccountId: account.id,
        userId: widget.user.uid,
        existingTransaction: txn,
      ),
    ));
  }

  void _deleteTransaction(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Transaction?',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'Delete "${txn.title}" — ${Formatters.currency(txn.amount)}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed, foregroundColor: Colors.white),
            onPressed: () {
              widget.firestoreService.deleteTransaction(txn);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
            child: Text('Error loading accounts',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
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
              MaterialPageRoute(builder: (_) => AddBankScreen(userId: widget.user.uid)),
            ),
          );
        }

        return StreamBuilder<List<TransactionModel>>(
          stream: widget.firestoreService.getAllTransactions(widget.user.uid),
          builder: (context, txnSnapshot) {
            final allTransactions = txnSnapshot.data ?? [];

            final txnByAccount = <String, List<TransactionModel>>{};
            for (final txn in allTransactions) {
              txnByAccount.putIfAbsent(txn.bankAccountId, () => []).add(txn);
            }

            final totalBalance =
                accounts.fold<double>(0, (sum, a) => sum + a.totalAmount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(FontAwesomeIcons.tableCellsLarge,
                            size: 15, color: AppColors.accentCyan),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Kanban Board',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${accounts.length} accs · ${allTransactions.length} txns · ${Formatters.compactCurrency(totalBalance)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.textHint),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accentCyan.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'Long-press to drag',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                // Kanban columns
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
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
                            onAddTransaction: () => _addTransaction(account),
                            onEditTransaction: (txn) =>
                                _editTransaction(txn, account),
                            onDeleteTransaction: _deleteTransaction,
                            onTapHeader: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BankDetailScreen(account: account),
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

// ── Helpers ────────────────────────────────────────────────────────────────────

List<Color> _colorsForAccount(BankAccountModel account) {
  final bankColors = AppColors.bankGradient(account.bankName);
  if (bankColors.isNotEmpty) return bankColors;
  switch (account.category) {
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

// ── Bank Account Column ────────────────────────────────────────────────────────

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
    final colors = _colorsForAccount(account);
    final columnColor = colors.first;

    double liveBalance = 0;
    for (final t in transactions) liveBalance += t.effectiveAmount;

    final creditCount = transactions.where((t) => t.type == TransactionType.credit).length;
    final debitCount  = transactions.where((t) => t.type == TransactionType.debit).length;

    return DragTarget<TransactionModel>(
      onWillAcceptWithDetails: (d) => d.data.bankAccountId != account.id,
      onAcceptWithDetails: (d) => onTransactionDropped(d.data),
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovering
                ? columnColor.withValues(alpha: 0.08)
                : AppColors.darkBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? columnColor : AppColors.darkBorder,
              width: isHovering ? 1.5 : 1,
            ),
            boxShadow: isHovering
                ? [BoxShadow(color: columnColor.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            children: [
              // ── Column Header ───────────────────────────────────
              GestureDetector(
                onTap: onTapHeader,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.buildingColumns,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              account.bankName,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${account.category.emoji} ${account.category.label}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Masked number / account
                      Text(
                        account.hasCard
                            ? account.maskedCardNumber
                            : 'ACCT: ${account.maskedAccountNumber}',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balance',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    Formatters.currency(liveBalance),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 18,
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
                                '${transactions.length} txns',
                                style: GoogleFonts.inter(
                                    color: Colors.white54, fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Add Transaction button ───────────────────────────
              GestureDetector(
                onTap: onAddTransaction,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  decoration: BoxDecoration(
                    color: columnColor.withValues(alpha: 0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.darkBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.plus, size: 10, color: columnColor),
                      const SizedBox(width: 6),
                      Text(
                        'Add Transaction',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: columnColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Drop hint ────────────────────────────────────────
              if (isHovering)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: columnColor.withValues(alpha: 0.06),
                  child: Center(
                    child: Text(
                      '⬇ Drop to move here',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: columnColor,
                      ),
                    ),
                  ),
                ),

              // ── Transaction list ─────────────────────────────────
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
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isHovering ? 'Drop here!' : 'No transactions',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isHovering ? columnColor : AppColors.textHint,
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

// ── Draggable transaction card ─────────────────────────────────────────────────

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
        color: Colors.transparent,
        child: SizedBox(
          width: 270,
          child: Opacity(
            opacity: 0.92,
            child: _TxnCardContent(txn: txn, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _TxnCardContent(txn: txn),
      ),
      child: _TxnCardContent(txn: txn, onEdit: onEdit, onDelete: onDelete),
    )
        .animate()
        .fadeIn(duration: 250.ms, delay: Duration(milliseconds: index * 50))
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }
}

// ── Compact transaction card content ──────────────────────────────────────────

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
      case TransactionStatus.pending:    return AppColors.accentAmber;
      case TransactionStatus.processing: return AppColors.primaryBlue;
      case TransactionStatus.completed:  return AppColors.accentGreen;
      case TransactionStatus.failed:     return AppColors.accentRed;
      case TransactionStatus.cancelled:  return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.type == TransactionType.credit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDragging ? AppColors.darkCardAlt : AppColors.darkCard,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isDragging ? AppColors.accentCyan : AppColors.darkBorder,
          width: isDragging ? 1.5 : 1,
        ),
        boxShadow: isDragging
            ? [BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 3),
              )]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    txn.title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
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
                      padding: EdgeInsets.only(left: 8),
                      child: FaIcon(FontAwesomeIcons.penToSquare,
                          size: 11, color: AppColors.textHint),
                    ),
                  ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FaIcon(FontAwesomeIcons.trash,
                          size: 11, color: AppColors.accentRed.withValues(alpha: 0.8)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Amount + status on same row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCredit ? AppColors.lightGreen : AppColors.lightAmber,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(txn.type.emoji, style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Text(
                        '${isCredit ? '+' : '−'}${Formatters.compactCurrency(txn.amount)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCredit ? AppColors.accentGreen : AppColors.accentAmber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(txn.status.emoji, style: const TextStyle(fontSize: 9)),
                      const SizedBox(width: 3),
                      Text(
                        txn.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // IST timestamp
            Row(
              children: [
                FaIcon(FontAwesomeIcons.clock, size: 8, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    Formatters.dateTimeIST(txn.timestamp),
                    style: GoogleFonts.inter(fontSize: 9, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (txn.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                txn.description,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
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