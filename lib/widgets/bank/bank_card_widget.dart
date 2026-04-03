import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
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
    // 1. Try bank-name-based gradient
    final bankColors = AppColors.bankGradient(account.bankName);
    if (bankColors.isNotEmpty) return bankColors;

    // 2. Fallback to category gradient
    switch (account.category) {
      case AccountCategory.savings:
        return AppColors.gradientSavings;
      case AccountCategory.expenses:
        return AppColors.gradientExpenses;
      case AccountCategory.fixed:
        return AppColors.gradientFixed;
      case AccountCategory.current:
        return AppColors.gradientCurrent;
      case AccountCategory.salary:
        return AppColors.gradientSalary;
      case AccountCategory.recurring:
        return AppColors.gradientRecurring;
      case AccountCategory.nri:
        return AppColors.gradientNRI;
      case AccountCategory.business:
        return AppColors.gradientBusiness;
      case AccountCategory.postalSavings:
        return AppColors.gradientPostal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.55),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative background circles
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: 10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Bank name + overflow menu ────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.buildingColumns,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          account.bankName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (onEdit != null || onDelete != null)
                        _CardMenu(onEdit: onEdit, onDelete: onDelete),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Row 2: Category badge + hasCard badge ────────
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Badge(
                        '${account.category.emoji} ${account.category.label}',
                        textColor: Colors.white,
                        bgColor: Colors.white.withValues(alpha: 0.2),
                      ),
                      if (!account.hasCard)
                        _Badge(
                          '📖 Account Only',
                          textColor: const Color(0xFFFFD54F),
                          bgColor: const Color(0xFFFFD54F).withValues(alpha: 0.18),
                          borderColor: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Card/Account section ─────────────────────────
                  if (account.hasCard) ...[
                    // EMV Chip + contactless icon
                    Row(
                      children: [
                        // Gold chip
                        Container(
                          width: 36,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 7,
                                left: 0,
                                right: 0,
                                child: Container(height: 1, color: Colors.black.withValues(alpha: 0.25)),
                              ),
                              Positioned(
                                top: 11,
                                left: 0,
                                right: 0,
                                child: Container(height: 1, color: Colors.black.withValues(alpha: 0.25)),
                              ),
                              Positioned(
                                left: 10,
                                top: 0,
                                bottom: 0,
                                child: Container(width: 1, color: Colors.black.withValues(alpha: 0.2)),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.wifi, color: Colors.white.withValues(alpha: 0.45), size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Masked card number
                    Text(
                      account.maskedCardNumber,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    // Account-only display
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.hashtag,
                            color: Colors.white.withValues(alpha: 0.5), size: 11),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ACCT: ${account.maskedAccountNumber}',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (account.ifscCode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          FaIcon(FontAwesomeIcons.buildingColumns,
                              color: Colors.white.withValues(alpha: 0.4), size: 10),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'IFSC: ${account.ifscCode}',
                              style: GoogleFonts.spaceMono(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),

                  // ── Balance + Validity row ───────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BALANCE',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Formatters.compactCurrency(account.totalAmount),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (account.hasCard && account.cardValidity != null) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VALID THRU',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                Formatters.monthYear(account.cardValidity!),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ── Bottom divider + credentials hint ────────────
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.lock,
                          color: Colors.white.withValues(alpha: 0.55), size: 9),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          account.hasCard
                              ? 'Tap to view credentials & transactions'
                              : 'Tap to view account details & transactions',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.5), size: 9),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.05, curve: Curves.easeOut);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;
  final Color? borderColor;

  const _Badge(this.text, {required this.textColor, required this.bgColor, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1) : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Overflow popup menu for edit/delete on the card.
class _CardMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CardMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.8), size: 20),
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.penToSquare, size: 13, color: AppColors.accentCyan),
                const SizedBox(width: 10),
                Text('Edit Account',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.trash, size: 13, color: AppColors.accentRed),
                const SizedBox(width: 10),
                Text('Delete Account',
                    style: GoogleFonts.inter(color: AppColors.accentRed, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}
