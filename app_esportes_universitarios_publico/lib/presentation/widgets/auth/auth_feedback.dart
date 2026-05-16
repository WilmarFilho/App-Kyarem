import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class AuthFeedback extends StatelessWidget {
  const AuthFeedback({
    super.key,
    this.error,
    this.success,
  });

  final String? error;
  final String? success;

  @override
  Widget build(BuildContext context) {
    final message = error ?? success;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final isError = error != null;
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
