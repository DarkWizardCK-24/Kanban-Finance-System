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

  bool get _isEditing => widget.existingAccount != null;

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
      _selectedValidity = a.cardValidity;
      _validityController.text = DateFormat('MM/yy').format(a.cardValidity);
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
      initialDate: _selectedValidity ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.greenAccent,
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
    if (_selectedValidity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select card validity date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        final updated = widget.existingAccount!.copyWith(
          bankName: _bankNameController.text.trim(),
          category: _selectedCategory,
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
          cardNumber: _cardNumberController.text.trim(),
          cvv: _cvvController.text.trim(),
          cardValidity: _selectedValidity,
        );
        await _firestoreService.updateBankAccount(updated);
      } else {
        await _firestoreService.createBankAccount(
          userId: widget.userId,
          bankName: _bankNameController.text.trim(),
          category: _selectedCategory,
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
          cardNumber: _cardNumberController.text.trim(),
          cvv: _cvvController.text.trim(),
          cardValidity: _selectedValidity!,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Bank account updated! ✅'
              : 'Bank account added! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
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
        title: Text(_isEditing ? 'Edit Bank Account ✏️' : 'Add Bank Account 🏦'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AccountCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const FaIcon(FontAwesomeIcons.chevronDown,
                        size: 14, color: AppColors.textHint),
                    items: AccountCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(
                              cat.label,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _bankNameController,
                label: 'Bank Name 🏦',
                hint: 'e.g., State Bank of India',
                prefixIcon: FontAwesomeIcons.buildingColumns,
                validator: (v) => Validators.required(v, 'Bank name'),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _accountNumberController,
                label: 'Account Number 🔢',
                hint: 'Enter account number',
                prefixIcon: FontAwesomeIcons.hashtag,
                keyboardType: TextInputType.number,
                validator: Validators.accountNumber,
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ifscController,
                label: 'IFSC Code 🏛️',
                hint: 'e.g., SBIN0001234',
                prefixIcon: FontAwesomeIcons.code,
                validator: Validators.ifscCode,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(11),
                ],
              ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cardNumberController,
                label: 'Card Number 💳',
                hint: 'Enter 16-digit card number',
                prefixIcon: FontAwesomeIcons.creditCard,
                keyboardType: TextInputType.number,
                validator: Validators.cardNumber,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cvvController,
                      label: 'CVV 🔒',
                      hint: '***',
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _validityController,
                      label: 'Validity 📅',
                      hint: 'MM/YY',
                      prefixIcon: FontAwesomeIcons.calendarCheck,
                      readOnly: true,
                      onTap: _pickValidity,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Select validity'
                          : null,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Account ✅' : 'Add Account 🎉',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
