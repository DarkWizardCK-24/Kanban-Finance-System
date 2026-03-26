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
        gradient: AppColors.wealthGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenAccent.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.vault,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Text(
                  '💎 Total Wealth',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.currency(summary.totalWealth),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatItem(
                  emoji: '📥',
                  label: 'Monthly In',
                  value: Formatters.compactCurrency(summary.monthlyInflow),
                  color: AppColors.greenAccent,
                ),
                _StatItem(
                  emoji: '📤',
                  label: 'Monthly Out',
                  value: Formatters.compactCurrency(summary.monthlyOutflow),
                  color: AppColors.primaryAmber,
                ),
                _StatItem(
                  emoji: '📊',
                  label: 'Net Flow',
                  value: Formatters.compactCurrency(summary.netMonthlyFlow),
                  color: summary.netMonthlyFlow >= 0
                      ? AppColors.greenAccent
                      : AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniChip('🏦 ${summary.totalAccounts} Accounts'),
                const SizedBox(width: 8),
                _MiniChip('📋 ${summary.totalTransactions} Transactions'),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
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
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  const _MiniChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
