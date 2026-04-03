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
      onWillAcceptWithDetails: (details) => details.data.status != targetStatus,
      onAcceptWithDetails: (details) => onTransactionDropped?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovering
                ? headerColor.withValues(alpha: 0.1)
                : backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? headerColor : AppColors.darkBorder,
              width: isHovering ? 1.5 : 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: headerColor.withValues(alpha: 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(
                    bottom: BorderSide(
                      color: headerColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: headerColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: headerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${transactions.length}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: headerColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Drop hint
              if (isHovering)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Text(
                      '⬇ Drop to move to $title',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: headerColor,
                      ),
                    ),
                  ),
                ),

              // Cards list
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            isHovering ? 'Drop here!' : 'No transactions',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isHovering ? headerColor : AppColors.textHint,
                              fontWeight:
                                  isHovering ? FontWeight.w600 : FontWeight.w400,
                            ),
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
        color: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: 280,
          child: Opacity(
            opacity: 0.92,
            child: TransactionCardWidget(
              transaction: transaction,
              index: 0,
              isDragging: true,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
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