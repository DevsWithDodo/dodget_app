import 'package:csocsort_szamla/app.dart';
import 'package:csocsort_szamla/helpers/initializers/supported_version_initializer.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/database_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/initializers/exchange_rate_initializer.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<SharedPreferences> _prefs;
  late DatabaseProvider databaseProvider;
  late PurchaseRepository purchaseRepository;

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
    databaseProvider = DatabaseProvider();
    purchaseRepository = PurchaseRepository(databaseProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AppConfigProvider(
      builder: (context) => FutureBuilder(
        future: _prefs,
        builder: (context, AsyncSnapshot<SharedPreferences> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return Provider(
            create: (context) => snapshot.data!,
            builder: (context, child) => AppThemeProvider(
              context: context,
              builder: (context) => 
              MultiProvider(providers: [
                Provider(create: (_) => DatabaseProvider()),
                Provider(create: (context) => PurchaseRepository(context.read<DatabaseProvider>())),
              ],
              child: ExchangeRateInitializer(
                  context: context,
                  builder: (context) => UserProvider(
                    context: context,
                    builder: (context) => ScreenSizeProvider(
                        builder: (context) => EasyLocalization(
                          child: ShowCaseWidget(
                            builder: (context) => SupportedVersionInitializer(
                              builder: (context) => App(),
                            ),
                          ),
                          supportedLocales: [Locale('en'), Locale('de'), Locale('hu')],
                          path: 'assets/translations',
                          fallbackLocale: Locale('en'),
                          useOnlyLangCode: true,
                          saveLocale: true,
                          useFallbackTranslations: true,
                        ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
