import 'dart:async';
import 'dart:math';

import 'package:csocsort_szamla/components/purchase/purchase_entry.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/customize_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemePreview extends StatefulWidget {
  const ThemePreview(
      {required this.themeName, required this.offset, super.key});

  final ThemeName themeName;
  final Offset offset;


  @override
  State<ThemePreview> createState() => _ThemePreviewState();
}

class _ThemePreviewState extends State<ThemePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _left;
  late Animation<double> _top;
  late Animation<double> _animationValue;
  late Animation<double> _borderRadius;

  late StreamSubscription _shouldHide;

  double _paddingHorizontal = 16;
  double _paddingVertical = 10;

  late final double _maxHeight;
  late final double _maxWidth;

  @override
  void initState() {
    super.initState();
    final screenSize = context.read<ScreenSize>();
    _controller = AnimationController(
        duration: Duration(milliseconds: 400),
        reverseDuration: Duration(milliseconds: 200),
        vsync: this)
      ..addListener(() => setState(() {}));

    _maxHeight = screenSize.height - 2 * _paddingVertical;
    _maxWidth = min(screenSize.width - 2 * _paddingHorizontal, 500);
    if (screenSize.width - 2 * _paddingHorizontal > 500) {
      _paddingHorizontal = (screenSize.width - 500) / 2;
    }

    final animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _left = Tween<double>(begin: widget.offset.dx, end: _paddingHorizontal)
        .animate(animation);
    _top = Tween<double>(
            begin: widget.offset.dy,
            end: _paddingVertical + screenSize.padding.top)
        .animate(animation);
    _animationValue = Tween<double>(begin: 0, end: 1).animate(animation);
    _borderRadius = Tween<double>(begin: 100, end: 15).animate(animation);

    _controller.forward();

    _shouldHide = context.read<StackWidgetState>().hide.listen((shouldHide) {
      if (shouldHide) {
        if (_controller.isAnimating) {
          _controller.stop();
        }
        _controller
            .reverse()
            .then((_) => context.read<StackWidgetState>().setWidget(null));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _shouldHide.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _top.value,
      left: _left.value,
      child: Stack(
        children: [
          Container(
            width: _maxWidth * _animationValue.value,
            height: _maxHeight * _animationValue.value,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_borderRadius.value),
            ),
            clipBehavior: Clip.antiAlias,
            child: _maxWidth * _animationValue.value < 250
                ? SizedBox()
                : ThemePreviewContent(themeName: widget.themeName),
          ),
          GestureDetector(
            onTap: () => context.read<ScreenSize>().isMobile ? context.read<StackWidgetState>().hideWidget() : context.read<StackWidgetState>().setWidget(null),
            child: Container(
              // Container to block tapping on examples
              width: _maxWidth,
              height: _maxHeight,
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class ThemePreviewContent extends StatelessWidget {
  final ThemeName themeName;
  const ThemePreviewContent({super.key, required this.themeName});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.getTheme(themeName),
      child: ChangeNotifierProvider(
        create: (context) => AppThemeState(themeName),
        builder: (context, child) => SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'balances'.tr(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'purchases'.tr(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
