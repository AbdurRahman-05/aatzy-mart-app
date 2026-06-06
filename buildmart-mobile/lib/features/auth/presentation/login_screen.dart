import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.login(
      _loginController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      final authState = ref.read(authProvider);
      if (authState.user?.roleName == 'supplier') {
        context.go('/supplier-dashboard');
      } else {
        context.go('/');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).errorMessage ?? 'Login credentials mismatch'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _googleSignIn() async {
    final notifier = ref.read(authProvider.notifier);
    // Mimic Google SignIn as a Buyer
    final success = await notifier.loginWithGoogle('amit@condev.com', 'Amit Sharma', 2);
    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        width: 72,
                        height: 72,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to BuildMart',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'India\'s premier B2B sourcing platform',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Form Fields
                TextFormField(
                  controller: _loginController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number or Email',
                    prefixIcon: Icon(Icons.phone_android_outlined, size: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 16),

                // Or Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Button
                OutlinedButton.icon(
                  onPressed: _googleSignIn,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: AppColors.textPrimary),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),

                const Spacer(flex: 1),

                // Bottom Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Register Now', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
