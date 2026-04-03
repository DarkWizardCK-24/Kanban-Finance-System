import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_text_field.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _authService = AuthService();

  DateTime? _selectedDob;
  int? _calculatedAge;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.greenAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd MMM yyyy').format(picked);
        _calculatedAge = UserModel.calculateAge(picked);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date of birth 📅'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDob!,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
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
        title: const Text('Create Account ✨'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join Kanban Finance 🚀',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  'Create your account to start managing wealth',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: FontAwesomeIcons.user,
                  validator: (v) => Validators.required(v, 'Name'),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: FontAwesomeIcons.envelope,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  prefixIcon: FontAwesomeIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _dobController,
                  label: 'Date of Birth 📅',
                  hint: 'Select date of birth',
                  prefixIcon: FontAwesomeIcons.cakeCandles,
                  readOnly: true,
                  onTap: _pickDateOfBirth,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Date of birth is required'
                      : null,
                ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
                if (_calculatedAge != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('🎂', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Age: $_calculatedAge years',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
                ],
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  prefixIcon: FontAwesomeIcons.lock,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: FaIcon(
                      _obscurePassword
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  prefixIcon: FontAwesomeIcons.shieldHalved,
                  obscureText: _obscureConfirm,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    child: FaIcon(
                      _obscureConfirm
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Create Account 🎉',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Login 🔐',
                        style: GoogleFonts.inter(
                          color: AppColors.greenAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
