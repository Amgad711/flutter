import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;
  final Color? backgroundColor;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      child: isLoading
          ? const SizedBox(
              height: 20, width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}
