import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUserUpdated;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _dobController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(widget.user.dateOfBirth),
    );
    _selectedDob = widget.user.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
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
        _selectedDob = picked;
        _dobController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final updated = widget.user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDob,
      );
      await _authService.updateUser(updated);
      widget.onUserUpdated();
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated! ✅'),
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
    final age = _selectedDob != null
        ? UserModel.calculateAge(_selectedDob!)
        : widget.user.age;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          AvatarWidget(initials: widget.user.initials, size: 80)
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            widget.user.name,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          Text(
            widget.user.id,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.greenAccent,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          if (!_isEditing) ...[
            // Read-only Profile Cards
            _ProfileInfoCard(
              icon: FontAwesomeIcons.user,
              label: 'Full Name',
              value: widget.user.name,
              emoji: '👤',
            ),
            _ProfileInfoCard(
              icon: FontAwesomeIcons.envelope,
              label: 'Email',
              value: widget.user.email,
              emoji: '📧',
            ),
            _ProfileInfoCard(
              icon: FontAwesomeIcons.phone,
              label: 'Phone',
              value: widget.user.phone,
              emoji: '📱',
            ),
            _ProfileInfoCard(
              icon: FontAwesomeIcons.cakeCandles,
              label: 'Date of Birth',
              value: DateFormat('dd MMM yyyy').format(widget.user.dateOfBirth),
              emoji: '🎂',
            ),
            _ProfileInfoCard(
              icon: FontAwesomeIcons.calendarDays,
              label: 'Age',
              value: '${widget.user.age} years',
              emoji: '🎯',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                label: Text('Edit Profile ✏️',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ] else ...[
            // Editable fields
            CustomTextField(
              controller: _nameController,
              label: 'Full Name 👤',
              prefixIcon: FontAwesomeIcons.user,
              validator: (v) => Validators.required(v, 'Name'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone 📱',
              prefixIcon: FontAwesomeIcons.phone,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _dobController,
              label: 'Date of Birth 🎂',
              prefixIcon: FontAwesomeIcons.cakeCandles,
              readOnly: true,
              onTap: _pickDob,
            ),
            if (_selectedDob != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Age: $age years (auto-calculated)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Save ✅',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String emoji;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FaIcon(icon, size: 16, color: AppColors.greenAccent),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $label',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }
}
