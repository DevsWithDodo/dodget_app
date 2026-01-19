import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends StatelessWidget {
  UserProvider({
    required BuildContext context,
    required this.builder,
    super.key,
  }) : _userState = UserState(context);

  late final UserState _userState;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _userState,
      builder: (context, _) => this.builder(context),
    );
  }
}

class UserState extends ChangeNotifier {
  AppSettings settings = AppSettings(currency: Currency.fromCode('EUR'));

  UserState(BuildContext context) {
    final preferences = context.read<SharedPreferences>();
  }

  void setRatedApp(bool ratedApp, {bool notify = true}) {
    settings!.ratedApp = ratedApp;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setBool('rated_app', ratedApp);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setUseGradients(bool useGradients, {bool notify = true}) {
    settings!.useGradients = useGradients;
    if (notify) {
      notifyListeners();
    }
  }

  void setPersonalisedAds(bool personalisedAds, {bool notify = true}) {
    settings!.personalisedAds = personalisedAds;
    if (notify) {
      notifyListeners();
    }
  }

  void setTrialVersion(bool trialVersion, {bool notify = true}) {
    settings!.trialVersion = trialVersion;
    if (notify) {
      notifyListeners();
    }
  }

  void setShownAds(bool showAds, {bool notify = true}) {
    settings!.showAds = showAds;
    if (notify) {
      notifyListeners();
    }
  }
}
