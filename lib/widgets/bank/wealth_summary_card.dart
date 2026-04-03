import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/wealth_calculator.dart';

class WealthSummaryCard extends StatelessWidget {
  final WealthSummary summary;

  const WealthSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B5E), Color(0xFF090E1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B5E).withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                  ),
                  child: const FaIcon(FontAwesomeIcons.vault,
                      color: AppColors.accentCyan, size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Wealth',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Secured Vault',
                      style: GoogleFonts.inter(
                        color: AppColors.accentCyan.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Formatters.currency(summary.totalWealth),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.08),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.darkDivider),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                _StatItem(
                  emoji: '📥',
                  label: 'Monthly In',
                  value: Formatters.compactCurrency(summary.monthlyInflow),
                  color: AppColors.accentGreen,
                ),
                _StatItem(
                  emoji: '📤',
                  label: 'Monthly Out',
                  value: Formatters.compactCurrency(summary.monthlyOutflow),
                  color: AppColors.accentAmber,
                ),
                _StatItem(
                  emoji: '📊',
                  label: 'Net Flow',
                  value: Formatters.compactCurrency(summary.netMonthlyFlow),
                  color: summary.netMonthlyFlow >= 0
                      ? AppColors.accentGreen
                      : AppColors.accentRed,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.darkDivider),
            const SizedBox(height: 14),
            // Savings / Fixed / Other breakdown row
            Row(
              children: [
                _StatItem(
                  emoji: '💰',
                  label: 'Savings',
                  value: Formatters.compactCurrency(summary.totalSavings),
                  color: AppColors.accentGreen,
                ),
                _StatItem(
                  emoji: '🔒',
                  label: 'Fixed Dep.',
                  value: Formatters.compactCurrency(summary.totalFixed + summary.totalRecurring),
                  color: AppColors.accentCyan,
                ),
                _StatItem(
                  emoji: '📦',
                  label: 'Other',
                  value: Formatters.compactCurrency(
                    summary.totalCurrent +
                        summary.totalSalary +
                        summary.totalNri +
                        summary.totalBusiness +
                        summary.totalExpenses,
                  ),
                  color: AppColors.accentAmber,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Account/transaction count chips
            Row(
              children: [
                _MiniChip(
                  '🏦 ${summary.totalAccounts} Accounts',
                  color: AppColors.accentCyan,
                ),
                const SizedBox(width: 8),
                _MiniChip(
                  '📋 ${summary.totalTransactions} Transactions',
                  color: AppColors.accentPurple,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.97, 0.97));
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniChip(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
