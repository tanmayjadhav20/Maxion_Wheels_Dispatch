import 'package:flutter/material.dart';

class RefreshGate extends StatefulWidget {
  final Widget child;
  final VoidCallback onRefresh;

  const RefreshGate({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<RefreshGate> createState() => _RefreshGateState();
}

class _RefreshGateState extends State<RefreshGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
