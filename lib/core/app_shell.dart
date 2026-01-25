import 'package:flutter/material.dart';
import 'package:usahaku_main/providers/product_provider.dart';
import 'package:usahaku_main/providers/dashboard_provider.dart';
import 'package:usahaku_main/providers/purchase_provider.dart';
import 'package:usahaku_main/providers/transaction_provider.dart';
import 'package:usahaku_main/providers/input_draft_provider.dart';
import 'package:provider/provider.dart';
import 'package:usahaku_main/widgets/custom_sidebar.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static AppShellState of(BuildContext context) {
    return context.findAncestorStateOfType<AppShellState>()!;
  }

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  final ValueNotifier<bool> _isSidebarOpen = ValueNotifier<bool>(false);

  void toggleSidebar() {
    _isSidebarOpen.value = !_isSidebarOpen.value;
  }

  @override
  void dispose() {
    _isSidebarOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background for contrast when scaling
      resizeToAvoidBottomInset: false,
      body: ValueListenableBuilder<bool>(
        valueListenable: _isSidebarOpen,
        builder: (context, isOpen, _) {
          return Stack(
            children: [
              // SCALABLE MAIN CONTENT - Animated Transformation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: isOpen ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  final scale = 1.0 - (value * 0.12);
                  final slide = value * 240.0;
                  final radius = value * 30.0;
                  
                  return Transform(
                    transform: Matrix4.identity()
                      ..translate(slide)
                      ..scale(scale),
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: RepaintBoundary(child: child),
                    ),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(key: ValueKey(widget.child.hashCode), child: widget.child),
                ),
              ),
              
              // INDEPENDENT SIDEBAR LAYER - Graphics Isolated
              RepaintBoundary(
                child: CustomSidebar(isOpen: _isSidebarOpen),
              ),
            ],
          );
        },
      ),
    );
  }
}
