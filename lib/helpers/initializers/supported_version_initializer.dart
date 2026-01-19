import 'package:flutter/material.dart';

class SupportedVersionInitializer extends StatefulWidget {
  const SupportedVersionInitializer({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  State<SupportedVersionInitializer> createState() => _SupportedVersionInitializerState();
}

class _SupportedVersionInitializerState extends State<SupportedVersionInitializer> {
  @override
  Widget build(BuildContext context) {
    // Simplified: always return the builder
    return widget.builder(context);
  }
}
