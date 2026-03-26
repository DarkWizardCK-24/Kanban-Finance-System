import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final String bankAccountId;
  final String userId;
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({
    super.key,
    required this.bankAccountId,
    required this.userId,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestoreService = FirestoreService();

  TransactionType _selectedType = TransactionType.credit;
  TransactionStatus _selectedStatus = TransactionStatus.completed;
  bool _isLoading = false;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTransaction!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _descriptionController.text = t.description;
      _selectedType = t.type;
      _selectedStatus = t.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        final updated = widget.existingTransaction!.copyWith(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          type: _selectedType,
          status: _selectedStatus,
          description: _descriptionController.text.trim(),
        );
        await _firestoreService.updateTransaction(updated);
      } else {
        await _firestoreService.createTransaction(
          bankAccountId: widget.bankAccountId,
          userId: widget.userId,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          type: _selectedType,
          status: _selectedStatus,
          description: _descriptionController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Transaction updated! ✅'
              : 'Transaction added! 🎉'),
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
        title: Text(
            _isEditing ? 'Edit Transaction ✏️' : 'Add Transaction 💸'),
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
              CustomTextField(
                controller: _titleController,
                label: 'Transaction Title 📝',
                hint: 'e.g., Salary, Rent, Grocery',
                prefixIcon: FontAwesomeIcons.tag,
                validator: (v) => Validators.required(v, 'Title'),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                label: 'Amount 💰',
                hint: 'Enter amount',
                prefixIcon: FontAwesomeIcons.indianRupeeSign,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
              ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
              const SizedBox(height: 16),

              // Transaction Type Dropdown
              Text(
                'Transaction Type',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TransactionType>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const FaIcon(FontAwesomeIcons.chevronDown,
                        size: 14, color: AppColors.textHint),
                    items: TransactionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Text(type.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(
                              type.label,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: type == TransactionType.credit
                                    ? AppColors.greenAccentDark
                                    : AppColors.primaryAmber,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // Status Dropdown
              Text(
                'Status',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TransactionStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    icon: const FaIcon(FontAwesomeIcons.chevronDown,
                        size: 14, color: AppColors.textHint),
                    items: TransactionStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Text(status.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(
                              status.label,
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
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional) 📝',
                hint: 'Add a note...',
                prefixIcon: FontAwesomeIcons.alignLeft,
                maxLines: 3,
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
              const SizedBox(height: 32),

              // Preview Card
              if (_amountController.text.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedType == TransactionType.credit
                        ? AppColors.lightGreen
                        : AppColors.lightAmber,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedType == TransactionType.credit
                          ? AppColors.greenAccentDark.withValues(alpha: 0.3)
                          : AppColors.primaryAmber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedType == TransactionType.credit
                            ? '📥'
                            : '📤',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preview',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                            Text(
                              '${_selectedType == TransactionType.credit ? '+' : '-'} ₹${_amountController.text}',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color:
                                    _selectedType == TransactionType.credit
                                        ? AppColors.greenAccentDark
                                        : AppColors.primaryAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedStatus.emoji} ${_selectedStatus.label}',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
              ],

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
                          _isEditing
                              ? 'Update Transaction ✅'
                              : 'Add Transaction 💸',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
