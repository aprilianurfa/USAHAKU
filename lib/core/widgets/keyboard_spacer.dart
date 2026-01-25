import 'package:flutter/material.dart';

/// A spacer that builds based on the current keyboard height
/// using [View.of(context)] to avoid root-level [MediaQuery] rebuilds.
class KeyboardSpacer extends StatelessWidget {
  final double extraPadding;
  const KeyboardSpacer({super.key, this.extraPadding = 20.0});

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery.viewInsetsOf to listen to keyboard height changes efficiently.
    // This triggers rebuilds only when the SPECIFIC inset changes.
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    
    return SizedBox(height: keyboardHeight > 0 ? keyboardHeight + extraPadding : extraPadding);
  }
}
