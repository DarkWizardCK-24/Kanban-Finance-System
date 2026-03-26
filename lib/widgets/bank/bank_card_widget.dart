import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bank_account_model.dart';
import '../../utils/formatters.dart';

class BankCardWidget extends StatelessWidget {
  final BankAccountModel account;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int index;

  const BankCardWidget({
    super.key,
    required this.account,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.index = 0,
  });

  List<Color> get _gradientColors {
    switch (account.category) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _gradientColors.first.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.buildingColumns,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        account.bankName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.penToSquare,
                              color: Colors.white70, size: 16),
                          onPressed: onEdit,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.trash,
                              color: Colors.white70, size: 16),
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${account.category.emoji} ${account.category.label}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                account.maskedCardNumber,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        account.id,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VALID THRU',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        Formatters.monthYear(account.cardValidity),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BALANCE',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        Formatters.compactCurrency(account.totalAmount),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.1);
  }
}
