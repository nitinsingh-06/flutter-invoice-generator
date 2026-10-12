import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/company_model.dart';
import '../../services/hive_service.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../../widgets/custom_text_field.dart';

/// Company Settings screen — collects and persists the business profile
/// used throughout the app (Home header, PDF header/footer, bank details).
///
/// [isFirstTimeSetup] changes two things:
/// - The AppBar back button is hidden (first-time users shouldn't be able
///   to dismiss this screen without saving, since Home requires a profile).
/// - On save, it navigates to [HomeScreen] instead of just popping back,
///   since there's nothing to pop back to on first launch.
class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key, required this.isFirstTimeSetup});

  final bool isFirstTimeSetup;

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _companyNameController;
  late final TextEditingController _gstController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _branchAddressController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;
  late final TextEditingController _upiController;

  String? _logoPath;
  String? _signaturePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with any existing profile, so editing settings
    // later doesn't wipe out previously saved data.
    final existing = HiveService.getCompanyProfile();

    _companyNameController = TextEditingController(text: existing?.companyName ?? '');
    _gstController = TextEditingController(text: existing?.gstNumber ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _branchAddressController = TextEditingController(text: existing?.branchAddress ?? '');
    _bankNameController = TextEditingController(text: existing?.bankName ?? '');
    _accountNumberController = TextEditingController(text: existing?.accountNumber ?? '');
    _ifscController = TextEditingController(text: existing?.ifscCode ?? '');
    _upiController = TextEditingController(text: existing?.upiId ?? '');
    _logoPath = existing?.logoPath;
    _signaturePath = existing?.signaturePath;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _branchAddressController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  /// Opens the gallery to pick either the company logo or the signature
  /// image, depending on [isLogo]. Storing just the file path (not the
  /// bytes) in Hive keeps the database small — the image itself stays on
  /// the device's filesystem, which image_picker already persists to.
  Future<void> _pickImage({required bool isLogo}) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      if (isLogo) {
        _logoPath = picked.path;
      } else {
        _signaturePath = picked.path;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final company = CompanyModel(
      logoPath: _logoPath,
      companyName: _companyNameController.text.trim(),
      gstNumber: _gstController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      branchAddress: _branchAddressController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      ifscCode: _ifscController.text.trim(),
      upiId: _upiController.text.trim(),
      signaturePath: _signaturePath,
    );

    await HiveService.saveCompanyProfile(company);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (widget.isFirstTimeSetup) {
      // First launch: go straight into the app, nothing to pop back to.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company profile saved')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings'),
        automaticallyImplyLeading: !widget.isFirstTimeSetup,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.isFirstTimeSetup) ...[
              Text(
                'Set up your business profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'This information appears on every invoice you generate.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
            ],
            _ImagePickerRow(
              label: 'Company Logo',
              imagePath: _logoPath,
              onPick: () => _pickImage(isLogo: true),
              onRemove: () => setState(() => _logoPath = null),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _companyNameController,
              label: 'Company Name',
              icon: Icons.storefront_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _gstController,
              label: 'GST Number',
              icon: Icons.badge_outlined,
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'GST number is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _branchAddressController,
              label: 'Branch Address (optional)',
              icon: Icons.apartment_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Bank Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _bankNameController,
              label: 'Bank Name',
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _accountNumberController,
              label: 'Account Number',
              icon: Icons.numbers_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _ifscController,
              label: 'IFSC Code',
              icon: Icons.pin_outlined,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _upiController,
              label: 'UPI ID',
              icon: Icons.qr_code_outlined,
            ),
            const SizedBox(height: 20),
            _ImagePickerRow(
              label: 'Authorized Signature',
              imagePath: _signaturePath,
              onPick: () => _pickImage(isLogo: false),
              onRemove: () => setState(() => _signaturePath = null),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Reusable image-picker row used for both the logo and the signature
/// image, avoiding duplicating the same preview/pick/remove UI twice.
class _ImagePickerRow extends StatelessWidget {
  const _ImagePickerRow({
    required this.label,
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  final String label;
  final String? imagePath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Row(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.file(File(imagePath!), fit: BoxFit.cover)
                : Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton(
                    onPressed: onPick,
                    child: Text(hasImage ? 'Change' : 'Upload'),
                  ),
                  if (hasImage)
                    TextButton(
                      onPressed: onRemove,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                      ),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
