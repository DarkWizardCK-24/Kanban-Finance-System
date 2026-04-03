import '../models/bank_account_model.dart';
import '../models/transaction_model.dart';

class WealthSummary {
  final double totalWealth;
  final double totalSavings;
  final double totalExpenses;
  final double totalFixed;
  final double totalCurrent;
  final double totalSalary;
  final double totalRecurring;
  final double totalNri;
  final double totalBusiness;
  final int totalAccounts;
  final int totalTransactions;
  final double monthlyInflow;
  final double monthlyOutflow;
  final double netMonthlyFlow;

  WealthSummary({
    required this.totalWealth,
    required this.totalSavings,
    required this.totalExpenses,
    required this.totalFixed,
    required this.totalCurrent,
    required this.totalSalary,
    required this.totalRecurring,
    required this.totalNri,
    required this.totalBusiness,
    required this.totalAccounts,
    required this.totalTransactions,
    required this.monthlyInflow,
    required this.monthlyOutflow,
    required this.netMonthlyFlow,
  });
}

class WealthCalculator {
  /// Core algorithm to calculate overall wealth from all bank accounts
  /// and their transactions. Applies rules based on account category.
  static WealthSummary calculateWealth({
    required List<BankAccountModel> accounts,
    required List<TransactionModel> transactions,
  }) {
    double totalWealth = 0;
    double totalSavings = 0;
    double totalExpenses = 0;
    double totalFixed = 0;
    double totalCurrent = 0;
    double totalSalary = 0;
    double totalRecurring = 0;
    double totalNri = 0;
    double totalBusiness = 0;
    double monthlyInflow = 0;
    double monthlyOutflow = 0;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (final account in accounts) {
      // Calculate account total from its transactions
      final accountTransactions = transactions
          .where((t) => t.bankAccountId == account.id)
          .toList();

      double accountTotal = 0;
      for (final txn in accountTransactions) {
        accountTotal += txn.effectiveAmount;

        // Calculate monthly flows
        if (txn.timestamp.isAfter(monthStart)) {
          if (txn.type == TransactionType.credit &&
              txn.status == TransactionStatus.completed) {
            monthlyInflow += txn.amount;
          } else if (txn.type == TransactionType.debit &&
              txn.status == TransactionStatus.completed) {
            monthlyOutflow += txn.amount;
          }
        }
      }

      // Apply category-based rules for wealth calculation
      switch (account.category) {
        case AccountCategory.savings:
          totalSavings += accountTotal;
          // Savings contribute 100% to wealth
          totalWealth += accountTotal;
          break;
        case AccountCategory.expenses:
          totalExpenses += accountTotal;
          // Expense accounts contribute to wealth as liquid assets
          totalWealth += accountTotal;
          break;
        case AccountCategory.fixed:
          totalFixed += accountTotal;
          // Fixed deposits are locked wealth - full value
          totalWealth += accountTotal;
          break;
        case AccountCategory.current:
          totalCurrent += accountTotal;
          // Current accounts - full liquid wealth
          totalWealth += accountTotal;
          break;
        case AccountCategory.salary:
          totalSalary += accountTotal;
          // Salary accounts - full value
          totalWealth += accountTotal;
          break;
        case AccountCategory.recurring:
          totalRecurring += accountTotal;
          // Recurring deposits - full value
          totalWealth += accountTotal;
          break;
        case AccountCategory.nri:
          totalNri += accountTotal;
          // NRI accounts - full value
          totalWealth += accountTotal;
          break;
        case AccountCategory.business:
          totalBusiness += accountTotal;
          // Business accounts - full value
          totalWealth += accountTotal;
          break;
        case AccountCategory.postalSavings:
          totalSavings += accountTotal;
          totalWealth += accountTotal;
          break;
      }
    }

    return WealthSummary(
      totalWealth: totalWealth,
      totalSavings: totalSavings,
      totalExpenses: totalExpenses,
      totalFixed: totalFixed,
      totalCurrent: totalCurrent,
      totalSalary: totalSalary,
      totalRecurring: totalRecurring,
      totalNri: totalNri,
      totalBusiness: totalBusiness,
      totalAccounts: accounts.length,
      totalTransactions: transactions.length,
      monthlyInflow: monthlyInflow,
      monthlyOutflow: monthlyOutflow,
      netMonthlyFlow: monthlyInflow - monthlyOutflow,
    );
  }

  /// Calculate total for a single bank account from its transactions
  static double calculateAccountTotal(List<TransactionModel> transactions) {
    double total = 0;
    for (final txn in transactions) {
      total += txn.effectiveAmount;
    }
    return total;
  }
}
