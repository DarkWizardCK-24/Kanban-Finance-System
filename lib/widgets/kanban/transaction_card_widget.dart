import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../utils/formatters.dart';

class TransactionCardWidget extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int index;
  final bool isDragging;

  const TransactionCardWidget({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.index = 0,
    this.isDragging = false,
  });

  Color get _statusColor {
    switch (transaction.status) {
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDragging ? AppColors.lightGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDragging ? AppColors.greenAccent : AppColors.divider,
            width: isDragging ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDragging
                  ? AppColors.greenAccent.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isDragging ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        GestureDetector(
                          onTap: onEdit,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: FaIcon(FontAwesomeIcons.penToSquare,
                                size: 13, color: AppColors.textHint),
                          ),
                        ),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: FaIcon(FontAwesomeIcons.trash,
                                size: 13, color: AppColors.error),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Amount
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: transaction.type == TransactionType.credit
                      ? AppColors.lightGreen
                      : AppColors.lightAmber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.type.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${transaction.type == TransactionType.credit ? '+' : '-'} ${Formatters.currency(transaction.amount)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: transaction.type == TransactionType.credit
                            ? AppColors.greenAccentDark
                            : AppColors.primaryAmber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Status and Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(transaction.status.emoji,
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          transaction.status.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.timeAgo(transaction.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              if (transaction.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  transaction.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'ID: ${transaction.id}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 60))
        .slideY(begin: 0.05);
  }
}
