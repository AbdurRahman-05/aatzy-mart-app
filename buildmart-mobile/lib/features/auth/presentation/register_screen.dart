import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Supplier additional fields
  final _companyNameController = TextEditingController();
  final _gstController = TextEditingController();
  final List<String> _selectedMaterials = [];
  
  double _mapPinX = 150.0;
  double _mapPinY = 100.0;
  String _selectedLocation = "Mumbai Hub (19.0760, 72.8777)";
  
  final List<String> _materialsOptions = [
    'Cement & Concrete',
    'Bricks & Blocks',
    'Steel & Rebars',
    'Electrical Wires',
    'Plumbing & Pipes',
    'Paints & Finishes',
    'Hardware Tools',
    'Solar Panels',
  ];

  int _selectedRoleId = 2; // Default to Buyer (2 = Buyer, 3 = Supplier)

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _updateLocationFromCoordinates(double x, double y) {
    // Generate dummy coordinates and location address name based on coordinates
    final lat = 19.0760 + (y - 100.0) * 0.0005;
    final lng = 72.8777 + (x - 150.0) * 0.0005;
    setState(() {
      _mapPinX = x;
      _mapPinY = y;
      _selectedLocation = "Supplier Yard (Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)})";
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRoleId == 3) {
      if (_selectedMaterials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one material you provide'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    final phone = _phoneController.text.trim();
    final otp = await ref.read(authProvider.notifier).register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      phone,
      _passwordController.text.trim(),
      _selectedRoleId,
      companyName: _selectedRoleId == 3 ? _companyNameController.text.trim() : null,
      location: _selectedRoleId == 3 ? _selectedLocation : null,
      gstNumber: _selectedRoleId == 3 ? _gstController.text.trim() : null,
      materialsProviding: _selectedRoleId == 3 ? _selectedMaterials.join(', ') : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mock OTP Code Sent: $otp'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Copy',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      // Navigate to OTP Screen
      context.push('/verify-otp', extra: phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Register to send inquiries or manage listings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Role selection Cards
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRoleId = 2),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedRoleId == 2 ? AppColors.primary.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedRoleId == 2 ? AppColors.primary : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined, color: _selectedRoleId == 2 ? AppColors.primary : AppColors.textSecondary, size: 28),
                            const SizedBox(height: 8),
                            Text('Register as Buyer', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _selectedRoleId == 2 ? AppColors.primary : AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRoleId = 3),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedRoleId == 3 ? AppColors.primary.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedRoleId == 3 ? AppColors.primary : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.storefront_outlined, color: _selectedRoleId == 3 ? AppColors.primary : AppColors.textSecondary, size: 28),
                            const SizedBox(height: 8),
                            Text('Register as Supplier', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _selectedRoleId == 3 ? AppColors.primary : AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Standard details
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name / Contact Person',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address (Optional)',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                ),
                validator: (value) => value == null || value.length < 6 ? 'Password must be 6+ chars' : null,
              ),
              
              // Supplier Specific Fields
              if (_selectedRoleId == 3) ...[
                const SizedBox(height: 24),
                const Divider(color: AppColors.border, thickness: 1.5),
                const SizedBox(height: 16),
                Text(
                  'Company Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.business_rounded, size: 20),
                  ),
                  validator: (value) => _selectedRoleId == 3 && (value == null || value.isEmpty) ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gstController,
                  decoration: const InputDecoration(
                    labelText: 'GST Number',
                    prefixIcon: Icon(Icons.assignment_ind_rounded, size: 20),
                    hintText: 'e.g., 27AAAAA1111A1Z1',
                  ),
                  validator: (value) {
                    if (_selectedRoleId == 3) {
                      if (value == null || value.isEmpty) {
                        return 'Required field';
                      }
                      if (value.length != 15) {
                        return 'GST must be exactly 15 characters';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Materials Providing:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _materialsOptions.map((material) {
                    final isSelected = _selectedMaterials.contains(material);
                    return ChoiceChip(
                      label: Text(material),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMaterials.add(material);
                          } else {
                            _selectedMaterials.remove(material);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tap Map to Set Business Location:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            _updateLocationFromCoordinates(
                              details.localPosition.dx,
                              details.localPosition.dy,
                            );
                          },
                          child: Image.network(
                            'https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?auto=format&fit=crop&w=800&q=80',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // The pin
                        Positioned(
                          left: _mapPinX - 20,
                          top: _mapPinY - 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                        ),
                        // Map scale visual helper
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: Colors.black.withOpacity(0.6),
                            child: const Text(
                              'Interactive Map',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedLocation,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Verification OTP'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
