import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';

class AppLoader extends StatelessWidget {
  final Color? color;
  final double? size;

  const AppLoader({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
