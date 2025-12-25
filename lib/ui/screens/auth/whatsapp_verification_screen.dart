import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/verification_provider.dart';
import '../../../ui/router/app_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class WhatsappVerificationScreen extends StatefulWidget {
  const WhatsappVerificationScreen({super.key});

  @override
  State<WhatsappVerificationScreen> createState() => _WhatsappVerificationScreenState();
}

class _WhatsappVerificationScreenState extends State<WhatsappVerificationScreen> {
  final _codeController = TextEditingController();
  bool _canResend = true;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60; // 60 seconds countdown
    });

    // Start countdown timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
          }
        });
      }
      return _resendCountdown > 0;
    });
  }

  Future<void> _handleVerifyWhatsapp() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final verificationProvider = Provider.of<VerificationProvider>(context, listen: false);
    final success = await verificationProvider.verifyWhatsapp(code);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp verified successfully! Welcome to KandLink!'),
          backgroundColor: Colors.green,
        ),
      );
      // Router will automatically redirect to home
    }
  }

  Future<void> _handleResendVerification() async {
    final verificationProvider = Provider.of<VerificationProvider>(context, listen: false);
    final success = await verificationProvider.resendVerification('whatsapp');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to WhatsApp!'),
          backgroundColor: Colors.green,
        ),
      );
      _startResendCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationProvider = Provider.of<VerificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify WhatsApp'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Icon and Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verify WhatsApp',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ve sent a verification code to your WhatsApp',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // WhatsApp Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Verification Required',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check your WhatsApp messages for the verification code.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Code Input
              CustomTextField(
                controller: _codeController,
                labelText: 'Verification Code',
                hintText: 'Enter the 6-digit code from WhatsApp',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.sms,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Verification code is required';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Error Message
              Consumer<VerificationProvider>(
                builder: (context, verificationProvider, child) {
                  if (verificationProvider.error != null) {
                    return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                        verificationProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                ),

              const SizedBox(height: 24),

              // Verify Button
              CustomButton(
                text: 'Verify WhatsApp',
                onPressed: verificationProvider.isLoading ? null : _handleVerifyWhatsapp,
                isLoading: verificationProvider.isLoading,
                backgroundColor: Colors.green,
              ),

              const SizedBox(height: 16),

              // Resend Code
              Consumer<VerificationProvider>(
                builder: (context, verificationProvider, child) => Center(
                child: TextButton(
                    onPressed: (_canResend && !verificationProvider.isLoading) ? _handleResendVerification : null,
                  child: Text(
                    _canResend
                        ? 'Resend Code via WhatsApp'
                        : 'Resend in ${_resendCountdown}s',
                    style: TextStyle(
                      color: _canResend
                          ? Colors.green[700]
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Skip Option (for development only - should be removed in production)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                  },
                  child: Text(
                    'Skip for now (Development)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
