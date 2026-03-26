import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/bank_account_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../utils/wealth_calculator.dart';
import '../../widgets/bank/bank_card_widget.dart';
import '../../widgets/bank/wealth_summary_card.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../auth/login_screen.dart';
import '../bank/add_bank_screen.dart';
import '../bank/bank_detail_screen.dart';
import '../kanban/account_kanban_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  UserModel? _user;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) setState(() => _user = user);
  }

  void _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: LoadingWidget(message: 'Loading...'));
    }

    final pages = [
      _DashboardPage(user: _user!, firestoreService: _firestoreService),
      _BankAccountsPage(
        user: _user!,
        firestoreService: _firestoreService,
      ),
      AccountKanbanScreen(
        user: _user!,
        firestoreService: _firestoreService,
      ),
      ProfileScreen(user: _user!, onUserUpdated: _loadUser),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 3),
              child: AvatarWidget(initials: _user!.initials, size: 36),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_user!.name.split(' ').first}! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _user!.id,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 18),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.chartLine, size: 20),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.buildingColumns, size: 20),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.tableCellsLarge, size: 20),
            label: 'Kanban',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user, size: 20),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 1 || _currentIndex == 2)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddBankScreen(userId: _user!.uid),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
              label: Text('Add Bank',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
          : null,
    );
  }
}

class _DashboardPage extends StatelessWidget {
  final UserModel user;
  final FirestoreService firestoreService;

  const _DashboardPage({required this.user, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wealth Summary
          FutureBuilder<WealthSummary>(
            future: firestoreService.getWealthSummary(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: AppColors.wealthGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Unable to load wealth summary',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: AppColors.wealthGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              return WealthSummaryCard(summary: snapshot.data!);
            },
          ),
          // Category Breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '📊 Category Breakdown',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BankAccountModel>>(
            stream: firestoreService.getBankAccounts(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final accounts = snapshot.data!;
              if (accounts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateWidget(
                    emoji: '🏦',
                    title: 'No Bank Accounts Yet',
                    subtitle: 'Add your first bank account to get started!',
                  ),
                );
              }

              // Group by category
              final grouped = <AccountCategory, double>{};
              for (final a in accounts) {
                grouped[a.category] =
                    (grouped[a.category] ?? 0) + a.totalAmount;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: grouped.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key.emoji} ${entry.key.label}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.compactCurrency(entry.value),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.95, 0.95));
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Recent Accounts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '🏦 Your Bank Accounts',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BankAccountModel>>(
            stream: firestoreService.getBankAccounts(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Error loading accounts. Pull to refresh.',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: LoadingWidget(),
                );
              }
              final accounts = snapshot.data!;
              if (accounts.isEmpty) return const SizedBox.shrink();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  return BankCardWidget(
                    account: accounts[index],
                    index: index,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BankDetailScreen(
                          account: accounts[index],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _BankAccountsPage extends StatelessWidget {
  final UserModel user;
  final FirestoreService firestoreService;

  const _BankAccountsPage({
    required this.user,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BankAccountModel>>(
      stream: firestoreService.getBankAccounts(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😕', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Error loading accounts',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and try again',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const LoadingWidget(message: 'Loading accounts...');
        }
        final accounts = snapshot.data!;
        if (accounts.isEmpty) {
          return EmptyStateWidget(
            emoji: '🏦',
            title: 'No Bank Accounts',
            subtitle: 'Tap the button below to add your first bank account!',
            actionLabel: 'Add Bank Account',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddBankScreen(userId: user.uid),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return BankCardWidget(
              account: account,
              index: index,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BankDetailScreen(account: account),
                ),
              ),
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddBankScreen(
                    userId: user.uid,
                    existingAccount: account,
                  ),
                ),
              ),
              onDelete: () => _confirmDelete(context, account),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, BankAccountModel account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${account.bankName}? 🗑️',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete this bank account and all its transactions.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              firestoreService.deleteBankAccount(account.id);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
