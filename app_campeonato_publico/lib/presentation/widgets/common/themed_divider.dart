import 'package:flutter/material.dart';

Widget buildThemedDivider() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
  );
}
