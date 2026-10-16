import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../viewmodels/auth/register_viewmodel.dart';

class RegisterFormFields extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirmPassword;
  final RegisterState registerState;
  final RegisterViewModel viewModel;
  final VoidCallback onShowTerms;
  final VoidCallback onSubmit;

  const RegisterFormFields({
    super.key,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirmPassword,
    required this.registerState,
    required this.viewModel,
    required this.onShowTerms,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Username Input Field
        TextFormField(
          controller: usernameController,
          onChanged: viewModel.setUsername,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'e.g. iron_athlete',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textInputAction: TextInputAction.next,
          enabled: !registerState.isLoading,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Username is required';
            }
            if (val.trim().length < 3) {
              return 'Username must be at least 3 characters long';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email Input Field
        TextFormField(
          controller: emailController,
          onChanged: viewModel.setEmail,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'athlete@hard.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !registerState.isLoading,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Email is required';
            }
            if (!val.contains('@') || !val.contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password Input Field
        TextFormField(
          controller: passwordController,
          onChanged: viewModel.setPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleObscurePassword,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          enabled: !registerState.isLoading,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Password is required';
            }
            if (val.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm Password Input Field
        TextFormField(
          controller: confirmPasswordController,
          onChanged: viewModel.setConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleObscureConfirmPassword,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          obscureText: obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          enabled: !registerState.isLoading,
          onFieldSubmitted: (_) => onSubmit(),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Please confirm your password';
            }
            if (val != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Terms & Conditions Checkbox
        CheckboxListTile(
          value: registerState.acceptTerms,
          onChanged:
              registerState.isLoading ? null : viewModel.setAcceptTerms,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.velocityLime,
          checkColor: AppTheme.velocityDark,
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'I agree to the ',
                style: TextStyle(fontSize: 13, color: AppTheme.velocityTextSecondary),
              ),
              GestureDetector(
                onTap: onShowTerms,
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.velocityLime,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Register Button
        ElevatedButton(
          onPressed: registerState.isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: AppTheme.velocityLimeBright,
            foregroundColor: AppTheme.velocityDark,
          ),
          child: registerState.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.velocityDark,
                  ),
                )
              : const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppTheme.velocityDark,
                  ),
                ),
        ),
      ],
    );
  }
}
