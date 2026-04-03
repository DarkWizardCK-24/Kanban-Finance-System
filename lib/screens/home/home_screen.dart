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
      _BankAccountsPage(user: _user!, firestoreService: _firestoreService),
      AccountKanbanScreen(user: _user!, firestoreService: _firestoreService),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${_user!.name.split(' ').first}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '🔒 Vault Finance',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 17),
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
            icon: FaIcon(FontAwesomeIcons.chartLine, size: 19),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.buildingColumns, size: 19),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.tableCellsLarge, size: 19),
            label: 'Kanban',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user, size: 19),
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
              icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
              label: Text('Add Account',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: AppColors.darkBg)),
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
          : null,
    );
  }
}

class _DashboardPage extends StatefulWidget {
  final UserModel user;
  final FirestoreService firestoreService;

  const _DashboardPage({required this.user, required this.firestoreService});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  late final PageController _cardPageController;
  int _currentCardPage = 0;

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController(viewportFraction: 0.87);
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wealth Summary
          FutureBuilder<WealthSummary>(
            future: widget.firestoreService.getWealthSummary(widget.user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: AppColors.wealthGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accentCyan),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: AppColors.wealthGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('Unable to load wealth summary',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  ),
                );
              }
              return WealthSummaryCard(summary: snapshot.data!);
            },
          ),

          // Category Breakdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Category Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          StreamBuilder<List<BankAccountModel>>(
            stream: widget.firestoreService.getBankAccounts(widget.user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
              final accounts = snapshot.data!;

              final grouped = <AccountCategory, double>{};
              for (final a in accounts) {
                grouped[a.category] = (grouped[a.category] ?? 0) + a.totalAmount;
              }

              final entries = grouped.entries.toList();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _CategoryChip(entry: entries[index]);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Bank Accounts header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Text('🏦', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Your Bank Accounts',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          StreamBuilder<List<BankAccountModel>>(
            stream: widget.firestoreService.getBankAccounts(widget.user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Error loading accounts',
                        style: GoogleFonts.inter(color: AppColors.accentRed)),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingWidget(),
                );
              }
              final accounts = snapshot.data!;
              final totalPages = accounts.length + 1; // +1 for Add Account card

              // Clamp current page in case accounts were deleted
              if (_currentCardPage >= totalPages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _currentCardPage = totalPages - 1);
                });
              }

              return Column(
                children: [
                  SizedBox(
                    height: 270,
                    child: PageView.builder(
                      controller: _cardPageController,
                      itemCount: totalPages,
                      onPageChanged: (i) => setState(() => _currentCardPage = i),
                      itemBuilder: (context, index) {
                        // Last page: Add Account card
                        if (index == accounts.length) {
                          return _AddAccountCard(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddBankScreen(userId: widget.user.uid),
                              ),
                            ),
                          );
                        }
                        // Account card pages
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: BankCardWidget(
                            account: accounts[index],
                            index: index,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BankDetailScreen(account: accounts[index]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PageIndicators(
                    count: totalPages,
                    currentPage: _currentCardPage,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final MapEntry<AccountCategory, double> entry;
  const _CategoryChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(entry.key.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.key.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.compactCurrency(entry.value),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ── Page Indicators ─────────────────────────────────────────────────────────
class _PageIndicators extends StatelessWidget {
  final int count;
  final int currentPage;

  const _PageIndicators({required this.count, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentCyan : AppColors.darkBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Add Account Card ─────────────────────────────────────────────────────────
class _AddAccountCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 0, 4, 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentCyan.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentCyan.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentCyan.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.accentCyan,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Add Account',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect a new bank account',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(
          begin: const Offset(0.95, 0.95),
          curve: Curves.easeOut,
        );
  }
}

class _BankAccountsPage extends StatelessWidget {
  final UserModel user;
  final FirestoreService firestoreService;

  const _BankAccountsPage({required this.user, required this.firestoreService});

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
                const Text('😕', style: TextStyle(fontSize: 44)),
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
                  'Check your connection and try again',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
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
              MaterialPageRoute(builder: (_) => AddBankScreen(userId: user.uid)),
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
                MaterialPageRoute(builder: (_) => BankDetailScreen(account: account)),
              ),
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddBankScreen(userId: user.uid, existingAccount: account),
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
        title: Text('Delete ${account.bankName}?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'This will permanently delete this account and all its transactions.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              firestoreService.deleteBankAccount(account.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
