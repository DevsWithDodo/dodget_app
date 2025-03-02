import 'package:csocsort_szamla/components/user_settings/cards/about_us.dart';
import 'package:csocsort_szamla/components/user_settings/cards/change_user_currency.dart';
import 'package:csocsort_szamla/components/user_settings/cards/delete_all_data.dart';
import 'package:csocsort_szamla/components/user_settings/cards/personalised_ads.dart';
import 'package:csocsort_szamla/components/user_settings/cards/report_bug.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserSettingsPage extends StatefulWidget {
  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = _settings();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profile'.tr(),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            if (context.select<ScreenSize, bool>(
                (screenWidth) => screenWidth.isMobile))
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _settings(),
                  ),
                ),
              )
            else
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: ScrollController(),
                        children: settings.take(3).toList(),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: ScrollController(),
                        children: settings
                            .reversed
                            .take(settings.length - 3)
                            .toList()
                            .reversed
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _settings() {
    return [
      ChangeUserCurrency(),
      Selector<UserState, bool>(
        selector: (context, provider) => provider.settings!.showAds,
        builder: (context, showAds, child) => Visibility(
          visible: showAds,
          child: PersonalisedAds(),
        ),
      ),
      AboutUs(),
      DeleteAllData(),
      ReportBug(),
    ];
  }
}
