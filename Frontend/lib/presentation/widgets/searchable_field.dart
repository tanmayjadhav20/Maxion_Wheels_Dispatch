import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SearchableField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchableField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search, color: context.textMuted, size: 18),
      ),
    );
  }
}
