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
        return AppColors.accentAmber;
      case TransactionStatus.processing:
        return AppColors.primaryBlue;
      case TransactionStatus.completed:
        return AppColors.accentGreen;
      case TransactionStatus.failed:
        return AppColors.accentRed;
      case TransactionStatus.cancelled:
        return AppColors.textHint;
    }
  }

  Color get _amountColor => transaction.type == TransactionType.credit
      ? AppColors.accentGreen
      : AppColors.accentAmber;

  Color get _amountBg => transaction.type == TransactionType.credit
      ? AppColors.lightGreen
      : AppColors.lightAmber;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDragging ? AppColors.darkCardAlt : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDragging ? AppColors.accentCyan : AppColors.darkBorder,
            width: isDragging ? 1.5 : 1,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 1: Title + action icons ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      transaction.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: FaIcon(FontAwesomeIcons.penToSquare,
                            size: 11, color: AppColors.textHint),
                      ),
                    ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: FaIcon(FontAwesomeIcons.trash,
                            size: 11, color: AppColors.accentRed.withValues(alpha: 0.8)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),

              // ── Row 2: Amount chip + Status badge ───────────────
              Row(
                children: [
                  // Amount
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _amountBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(transaction.type.emoji,
                            style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          '${transaction.type == TransactionType.credit ? '+' : '−'}'
                          '${Formatters.compactCurrency(transaction.amount)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(transaction.status.emoji,
                            style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(
                          transaction.status.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Row 3: IST timestamp ─────────────────────────────
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock,
                      size: 9, color: AppColors.textHint),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      Formatters.dateTimeIST(transaction.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textHint,
                        height: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── Optional description ─────────────────────────────
              if (transaction.description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  transaction.description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, delay: Duration(milliseconds: index * 50))
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }
}