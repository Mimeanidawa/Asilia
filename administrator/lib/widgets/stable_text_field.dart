import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/admin_colors.dart';

/// Text field that keeps its own controller so typing does not reset the cursor.
class StableTextField extends StatefulWidget {
  const StableTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.style,
    this.decoration,
    this.keyboardType,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final int? minLines;
  final TextStyle? style;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;

  @override
  State<StableTextField> createState() => _StableTextFieldState();
}

class _StableTextFieldState extends State<StableTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _controller.addListener(_handleChange);
  }

  void _handleChange() {
    if (_controller.text != widget.value) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(StableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      final sel = _controller.selection;
      _controller.text = widget.value;
      _controller.selection = sel.isValid
          ? sel.copyWith(
              baseOffset: sel.baseOffset.clamp(0, widget.value.length),
              extentOffset: sel.extentOffset.clamp(0, widget.value.length),
            )
          : TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14, height: 1.5);
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      style: baseStyle,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(color: AdminColors.textDim),
            filled: true,
            fillColor: AdminColors.bg,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminColors.emerald, width: 1.5),
            ),
          ),
    );
  }
}
