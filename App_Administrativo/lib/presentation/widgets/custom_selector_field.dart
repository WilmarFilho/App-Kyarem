import 'package:flutter/material.dart';

class CustomSelectorField<T> extends StatelessWidget {
  final String label;
  final String? valueText;
  final String hint;
  final bool isLoading;
  final VoidCallback? onTap;
  final FormFieldValidator<T>? validator;
  final T? value;

  const CustomSelectorField({
    Key? key,
    required this.label,
    this.valueText,
    required this.hint,
    this.isLoading = false,
    this.onTap,
    this.validator,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      validator: validator,
      initialValue: value,
      builder: (FormFieldState<T> state) {
        final hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: isLoading ? null : onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasError
                        ? Colors.red.shade400
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasError
                                  ? Colors.red.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isLoading)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text(
                              valueText ?? hint,
                              style: TextStyle(
                                fontSize: 16,
                                color: valueText == null
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                                fontWeight: valueText == null
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
