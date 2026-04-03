import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/bank_account_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_text_field.dart';

class AddBankScreen extends StatefulWidget {
  final String userId;
  final BankAccountModel? existingAccount;

  const AddBankScreen({
    super.key,
    required this.userId,
    this.existingAccount,
  });

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _validityController = TextEditingController();
  final _firestoreService = FirestoreService();

  AccountCategory _selectedCategory = AccountCategory.savings;
  DateTime? _selectedValidity;
  bool _isLoading = false;
  bool _hasCard = true; // false for passbook/account-only banks

  bool get _isEditing => widget.existingAccount != null;
  bool get _isPostalSavings => _selectedCategory == AccountCategory.postalSavings;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final a = widget.existingAccount!;
      _bankNameController.text = a.bankName;
      _accountNumberController.text = a.accountNumber;
      _ifscController.text = a.ifscCode;
      _cardNumberController.text = a.cardNumber;
      _cvvController.text = a.cvv;
      _selectedCategory = a.category;
      _hasCard = a.hasCard;
      _selectedValidity = a.cardValidity;
      if (a.cardValidity != null) {
        _validityController.text = DateFormat('MM/yy').format(a.cardValidity!);
      }
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  Future<void> _pickValidity() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedValidity ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentCyan,
              onPrimary: AppColors.darkBg,
              surface: AppColors.darkSurface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedValidity = picked;
        _validityController.text = DateFormat('MM/yy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Card validity required only when hasCard is true (not for postal savings)
    if (!_isPostalSavings && _hasCard && _selectedValidity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select card validity date',
              style: GoogleFonts.inter(color: AppColors.textPrimary)),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        // Construct the model directly to properly handle null cardValidity
        final existing = widget.existingAccount!;
        final updated = BankAccountModel(
          id: existing.id,
          userId: existing.userId,
          bankName: _bankNameController.text.trim(),
          category: _selectedCategory,
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _isPostalSavings ? '' : _ifscController.text.trim().toUpperCase(),
          cardNumber: _hasCard ? _cardNumberController.text.trim() : '',
          cvv: _hasCard ? _cvvController.text.trim() : '',
          cardValidity: _hasCard ? _selectedValidity : null,
          hasCard: _hasCard,
          totalAmount: existing.totalAmount,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateBankAccount(updated);
      } else {
        await _firestoreService.createBankAccount(
          userId: widget.userId,
          bankName: _bankNameController.text.trim(),
          category: _selectedCategory,
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _isPostalSavings ? '' : _ifscController.text.trim().toUpperCase(),
          cardNumber: _hasCard ? _cardNumberController.text.trim() : '',
          cvv: _hasCard ? _cvvController.text.trim() : '',
          cardValidity: _hasCard ? _selectedValidity : null,
          hasCard: _hasCard,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Bank account updated ✅' : 'Bank account added 🎉',
            style: GoogleFonts.inter(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.darkCard,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(),
              style: GoogleFonts.inter(color: AppColors.textPrimary)),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Bank Account' : 'Add Bank Account'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Section: Account Info ────────────────────────────
              _SectionHeader(icon: FontAwesomeIcons.buildingColumns, label: 'Account Information'),
              const SizedBox(height: 12),

              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AccountCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppColors.darkCard,
                    icon: const FaIcon(FontAwesomeIcons.chevronDown,
                        size: 13, color: AppColors.textHint),
                    items: AccountCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(cat.emoji,
                                style: const TextStyle(fontSize: 17)),
                            const SizedBox(width: 10),
                            Text(
                              cat.label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                          if (val == AccountCategory.postalSavings) {
                            _hasCard = false;
                          }
                        });
                      }
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _bankNameController,
                label: 'Bank / Institution Name',
                hint: 'e.g., State Bank of India, India Post',
                prefixIcon: FontAwesomeIcons.buildingColumns,
                validator: (v) => Validators.required(v, 'Bank name'),
              ).animate().fadeIn(delay: 120.ms).slideX(begin: -0.08),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _accountNumberController,
                label: 'Account Number',
                hint: 'Enter account number (6–18 digits)',
                prefixIcon: FontAwesomeIcons.hashtag,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(18),
                ],
                validator: Validators.accountNumber,
              ).animate().fadeIn(delay: 160.ms).slideX(begin: -0.08),
              const SizedBox(height: 14),

              if (!_isPostalSavings) ...[
                CustomTextField(
                  controller: _ifscController,
                  label: 'IFSC Code',
                  hint: 'e.g., SBIN0001234',
                  prefixIcon: FontAwesomeIcons.code,
                  validator: Validators.ifscCode,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(11),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.08),
                const SizedBox(height: 20),
              ],

              if (!_isPostalSavings) ...[
              // ── Section: Card Credentials Toggle ─────────────────
              _SectionHeader(icon: FontAwesomeIcons.creditCard, label: 'Card Credentials'),
              const SizedBox(height: 12),

              // Has card toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasCard ? AppColors.accentCyan.withValues(alpha: 0.4) : AppColors.darkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (_hasCard ? AppColors.accentCyan : AppColors.accentGold)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        _hasCard ? FontAwesomeIcons.creditCard : FontAwesomeIcons.bookOpen,
                        size: 13,
                        color: _hasCard ? AppColors.accentCyan : AppColors.accentGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasCard ? 'Has Debit/Credit Card' : 'Account / Passbook Only',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _hasCard
                                ? 'Card number, CVV & expiry required'
                                : 'No card — e.g. Post Office, Postal Savings',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hasCard,
                      onChanged: (v) => setState(() => _hasCard = v),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 240.ms),
              const SizedBox(height: 14),

              // Card fields — only shown when hasCard is true
              if (_hasCard) ...[
                CustomTextField(
                  controller: _cardNumberController,
                  label: 'Card Number',
                  hint: '16-digit card number',
                  prefixIcon: FontAwesomeIcons.creditCard,
                  keyboardType: TextInputType.number,
                  validator: Validators.cardNumber,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                ).animate().fadeIn(delay: 280.ms).slideX(begin: -0.08),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cvvController,
                        label: 'CVV',
                        hint: '•••',
                        prefixIcon: FontAwesomeIcons.shieldHalved,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        validator: Validators.cvv,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        controller: _validityController,
                        label: 'Valid Thru',
                        hint: 'MM/YY',
                        prefixIcon: FontAwesomeIcons.calendarCheck,
                        readOnly: true,
                        onTap: _pickValidity,
                        validator: (v) => _hasCard && (v == null || v.isEmpty)
                            ? 'Select validity'
                            : null,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 320.ms).slideX(begin: -0.08),
                const SizedBox(height: 6),
              ],
              ], // end if (!_isPostalSavings)

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.darkBg,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Account' : 'Add Account',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBg,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.08),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, size: 12, color: AppColors.accentCyan),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}