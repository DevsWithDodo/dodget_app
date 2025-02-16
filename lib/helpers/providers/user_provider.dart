import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
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

  Group group = Group(name: "asd", id: 1, currency: Currency.fromCodeSafe('EUR'));

  UserState(BuildContext context) {
    final preferences = context.read<SharedPreferences>();
  }


  void setGroup(Group? group, {bool notify = true}) {
    group = group;
    SharedPreferences.getInstance().then((preferences) {
      if (group == null) {
        preferences.remove('current_group_name');
        preferences.remove('current_group_id');
        preferences.remove('current_group_currency');
        return;
      }
      preferences.setString('current_group_name', group.name);
      preferences.setInt('current_group_id', group.id);
      preferences.setString('current_group_currency', group.currency.code);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setGroupName(String name, {bool notify = true}) {
    group!.name = name;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_group_name', name);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setGroupCurrency(Currency currency, {bool notify = true}) {
    group!.currency = currency;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_group_currency', currency.code);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setUserCurrency(String currency, {bool notify = true}) {
    settings!.currency = Currency.fromCode(currency);
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_user_currency', currency);
    });
    if (notify) {
      notifyListeners();
    }
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

class LoginFutureOutputs extends FutureOutput {
  static const main = LoginFutureOutputs(true, 'main');
  static const joinGroup = LoginFutureOutputs(true, 'joinGroup');
  static const joinGroupFromAuth = LoginFutureOutputs(true, 'joinGroupFromAuth');

  const LoginFutureOutputs(super.value, super.name);
}
