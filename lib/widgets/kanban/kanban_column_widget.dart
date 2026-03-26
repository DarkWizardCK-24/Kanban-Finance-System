import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/transaction_model.dart';
import 'transaction_card_widget.dart';

class KanbanColumnWidget extends StatelessWidget {
  final String title;
  final String emoji;
  final Color headerColor;
  final Color backgroundColor;
  final List<TransactionModel> transactions;
  final void Function(TransactionModel)? onEditTransaction;
  final void Function(TransactionModel)? onDeleteTransaction;
  final void Function(TransactionModel)? onTransactionDropped;
  final TransactionStatus targetStatus;

  const KanbanColumnWidget({
    super.key,
    required this.title,
    required this.emoji,
    required this.headerColor,
    required this.backgroundColor,
    required this.transactions,
    required this.targetStatus,
    this.onEditTransaction,
    this.onDeleteTransaction,
    this.onTransactionDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<TransactionModel>(
      onWillAcceptWithDetails: (details) {
        // Accept if the transaction is not already in this status
        return details.data.status != targetStatus;
      },
      onAcceptWithDetails: (details) {
        onTransactionDropped?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovering
                ? headerColor.withValues(alpha: 0.12)
                : backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? headerColor : AppColors.divider,
              width: isHovering ? 2 : 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: headerColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.15),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: headerColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: headerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${transactions.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: headerColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Drop zone hint when hovering
              if (isHovering)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Drop here to move to $title',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: headerColor,
                      ),
                    ),
                  ),
                ),
              // Column Body
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isHovering ? 'Drop here!' : 'No transactions',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isHovering
                                      ? headerColor
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
                        padding: const EdgeInsets.all(10),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final txn = transactions[index];
                          return DraggableTransactionCard(
                            transaction: txn,
                            index: index,
                            onEdit: onEditTransaction != null
                                ? () => onEditTransaction!(txn)
                                : null,
                            onDelete: onDeleteTransaction != null
                                ? () => onDeleteTransaction!(txn)
                                : null,
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

class DraggableTransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DraggableTransactionCard({
    super.key,
    required this.transaction,
    required this.index,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<TransactionModel>(
      data: transaction,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        shadowColor: AppColors.greenAccent.withValues(alpha: 0.4),
        child: SizedBox(
          width: 280,
          child: TransactionCardWidget(
            transaction: transaction,
            index: 0,
            isDragging: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: TransactionCardWidget(
          transaction: transaction,
          index: 0,
        ),
      ),
      child: TransactionCardWidget(
        transaction: transaction,
        index: index,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}
