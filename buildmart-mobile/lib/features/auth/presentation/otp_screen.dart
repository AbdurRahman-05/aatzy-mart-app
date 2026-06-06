import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() async {
    if (_otpController.text.length < 4) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(
      widget.phone,
      _otpController.text.trim(),
    );

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user?.roleName == 'supplier') {
        context.go('/pending-approval');
      } else {
        context.go('/');
      }
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Invalid Verification OTP Code'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 70, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Enter OTP Code',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A verification code has been simulated and sent to your mobile: ${widget.phone}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // OTP Input
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '******',
                hintStyle: TextStyle(color: AppColors.border, fontSize: 24),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: authState.isLoading ? null : _verify,
              child: authState.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Continue'),
            ),
            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock OTP resent successfully!')),
                  );
                },
                child: const Text('Resend Code', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
