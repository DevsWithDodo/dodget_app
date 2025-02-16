import 'dart:math';

import 'package:csocsort_szamla/components/main/dialogs/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/components/main/dialogs/personalised_ads_dialog.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/like_app.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/main_dialog.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/payment_method.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/themes.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainDialogBuilder extends StatefulWidget {
  late final List<MainDialog> dialogs;
  late final MainDialog? chosenDialog;
  final BuildContext context;

  MainDialogBuilder({required this.context, super.key}) {
    dialogs = [
      ThemesMainDialog(
        canShow: (context) {
          UserState provider = context.read<UserState>();
          ThemeName currentTheme = context.read<AppThemeState>().themeName;
          late double chance;
          chance = currentTheme == ThemeName.greenLight || currentTheme == ThemeName.greenDark ? 0.1 : 0.05;
          return Random().nextDouble() <= chance;
        },
        type: DialogType.bottom,
        showTime: DialogShowTime.onBuild,
      ),
    ];
    chosenDialog = chooseWidget(DialogShowTime.onInit, context);
  }

  MainDialog? chooseWidget(DialogShowTime showTime, BuildContext context) {
    return dialogs.where((dialog) => (dialog.showTime == showTime || dialog.showTime == DialogShowTime.both) && dialog.canShow(context)).firstOrNull;
  }

  @override
  State<MainDialogBuilder> createState() => _MainDialogBuilderState();
}

class _MainDialogBuilderState extends State<MainDialogBuilder> {
  late MainDialog? _dialog;
  late bool visible;

  void onRefreshMainDialog() {
    if (!visible) {
      setState(() {
        _dialog = widget.chooseWidget(DialogShowTime.onBuild, getIt.get<NavigationService>().navigatorKey.currentContext!);
        visible = _dialog != null;
      });
    }
  }

  void onHideMainDialog() {
    setState(() {
      visible = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _dialog = widget.chosenDialog;
    visible = _dialog != null;

    EventBus.instance.register(EventBus.refreshMainDialog, onRefreshMainDialog);
    EventBus.instance.register(EventBus.hideMainDialog, onHideMainDialog);
  }

  @override
  void dispose() {
    EventBus.instance.unregister(EventBus.refreshMainDialog, onRefreshMainDialog);
    EventBus.instance.unregister(EventBus.hideMainDialog, onHideMainDialog);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Stack(
        children: [
          Positioned.fill(
            child: Visibility(
              visible: _dialog?.type == DialogType.modal,
              child: GestureDetector(
                onTap: () => _dialog!.onDismiss != null ? _dialog!.onDismiss!(context) : setState(() => visible = false),
                child: Container(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: _dialog?.type == DialogType.modal ? Alignment.center : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: _dialog?.type == DialogType.bottom ? (context.select<ScreenSize, bool>((provider) => provider.isMobile) ? 95 : 15) : 0),
                child: Provider.value(
                  value: () => setState(() {
                    visible = false;
                    _dialog?.onDismiss?.call(context);
                  }),
                  builder: (context, _) {
                    return _dialog!;
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
