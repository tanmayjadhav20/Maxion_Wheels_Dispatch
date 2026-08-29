import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ResponsiveTabBar extends StatefulWidget {
  final TabController controller;
  final List<Widget> tabs;
  final Color? indicatorColor;
  final Color? labelColor;

  const ResponsiveTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.indicatorColor,
    this.labelColor,
  });

  @override
  State<ResponsiveTabBar> createState() => _ResponsiveTabBarState();
}

class _ResponsiveTabBarState extends State<ResponsiveTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  void _prevTab() {
    if (widget.controller.index > 0) {
      widget.controller.animateTo(widget.controller.index - 1);
    }
  }

  void _nextTab() {
    if (widget.controller.index < widget.tabs.length - 1) {
      widget.controller.animateTo(widget.controller.index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.controller.index;
    final totalTabs = widget.tabs.length;
    final indColor = widget.indicatorColor ?? AppColors.ribbonPink;
    final lblColor = widget.labelColor ?? context.brandInk;

    return Container(
      decoration: BoxDecoration(
        color: context.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: 'Previous Tab / Page',
            color: currentIndex > 0 ? indColor : context.textMuted.withValues(alpha: 0.4),
            onPressed: currentIndex > 0 ? _prevTab : null,
          ),
          Expanded(
            child: TabBar(
              controller: widget.controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: indColor,
              indicatorWeight: 3,
              labelColor: lblColor,
              unselectedLabelColor: context.textMuted,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: widget.tabs,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Next Tab / Page',
            color: currentIndex < totalTabs - 1 ? indColor : context.textMuted.withValues(alpha: 0.4),
            onPressed: currentIndex < totalTabs - 1 ? _nextTab : null,
          ),
        ],
      ),
    );
  }
}
