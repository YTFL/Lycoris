import 'package:flutter/material.dart';

/// Helper utility for text field interactions and ergonomics.
class TextFieldHelper {
  /// Automatically selects all text in a [TextEditingController] when the user taps into the field,
  /// enabling immediate overwriting without requiring manual backspacing.
  static void selectAll(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      Future.microtask(() {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      });
    }
  }
}
