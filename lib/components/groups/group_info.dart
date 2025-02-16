import 'dart:convert';

import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/main/dialogs/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class GroupInfo extends StatefulWidget {
  const GroupInfo({
    super.key,
  });

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  Future<bool>? _isUserAdmin;
  Future<Map<String, dynamic>>? _boostNumber;

  Future<bool> _getIsUserAdmin() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupMember, context),
        useCache: false,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['is_admin'] == 1;
    } catch (_) {
      throw _;
    }
  }

  void onTapStore() async {
      showDialog(
        context: context,
        builder: (context) => IAPNotSupportedDialog(),
      );
  }

  void onRefreshGroupInfoEvent() {
    setState(() {
      _isUserAdmin = _getIsUserAdmin();
    });
  }

  @override
  void initState() {
    super.initState();
    _isUserAdmin = _getIsUserAdmin();
    EventBus.instance.register(EventBus.refreshGroupInfo, onRefreshGroupInfoEvent);
  }

  @override
  void dispose() {
    EventBus.instance.unregister(EventBus.refreshGroupInfo, onRefreshGroupInfoEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<UserState>().group!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text('group-info'.tr(), style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 10),
            FutureBuilder(
              future: _isUserAdmin,
              builder: (context, adminSnapshot) {
                return FutureBuilder(
                  future: _boostNumber,
                  builder: (context, boostSnapshot) {
                    if (adminSnapshot.connectionState != ConnectionState.done || boostSnapshot.connectionState != ConnectionState.done) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (adminSnapshot.hasError || boostSnapshot.hasError) {
                      return ErrorMessage(
                          error: (adminSnapshot.error ?? boostSnapshot.error).toString(),
                          onTap: () {
                            setState(() {
                              _isUserAdmin = _getIsUserAdmin();
                            });
                          });
                    }
                    final bool isBoosted = boostSnapshot.data!['is_boosted'] == 1;
                    final int boostsAvailable = boostSnapshot.data!['available_boosts'];
                    final bool isAdmin = adminSnapshot.data!;

                    final TapGestureRecognizer recognizer = TapGestureRecognizer();
                    recognizer.onTap = onTapStore;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.labelLarge,
                                  children: [
                                    TextSpan(text: 'group-info.name'.tr() + ': '),
                                    TextSpan(
                                      text: group.name,
                                      style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.labelLarge,
                                  children: [
                                    TextSpan(text: 'group-info.currency'.tr() + ': '),
                                    TextSpan(
                                      text: group.currency.code + "(${group.currency.symbol})",
                                      style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                      
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
