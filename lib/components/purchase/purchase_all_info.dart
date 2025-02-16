import 'package:csocsort_szamla/components/helpers/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/purchase_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PurchaseAllInfo extends StatefulWidget {
  final Purchase purchase;
  final int? selectedMemberId;

  PurchaseAllInfo(this.purchase, this.selectedMemberId);

  @override
  _PurchaseAllInfoState createState() => _PurchaseAllInfoState();
}

class _PurchaseAllInfoState extends State<PurchaseAllInfo> {
  late Currency displayCurrency;

  @override
  void initState() {
    super.initState();
    displayCurrency = widget.purchase.currency;
  }

  Future<BoolFutureOutput> _deleteElement(int id) async {
    try {
      await Http.delete(uri: '/purchases/' + id.toString());
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _sendReaction(String reaction) async {
    try {
      Map<String, dynamic> body = {"purchase_id": widget.purchase.id, "reaction": reaction};
      await Http.post(uri: '/purchases/reaction', body: body);
      return true;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    String note = '';
    if (widget.purchase.name == '') {
      note = 'no_note'.tr();
    } else {
      note = widget.purchase.name[0].toUpperCase() + widget.purchase.name.substring(1);
    }

    TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    Currency groupCurrency = context.select<UserState, Currency>((provider) => provider.group!.currency);

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'purchase-info.title'.tr(namedArgs: {
                      'note': note,
                    }),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Visibility(
              visible: widget.purchase.category != null,
              child: Row(
                children: [
                  Text(
                    "${'purchase-info.category'.tr()} - ",
                    style: titleStyle,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text(
                        widget.purchase.category?.tr() ?? "",
                      ),
                    ),
                  ),
                  Icon(
                    widget.purchase.category?.icon,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "${'info.date'.tr()} - ",
                  style: titleStyle,
                ),
                Flexible(
                  child: Text(
                    DateFormat.yMd(context.locale.languageCode).add_Hm().format(widget.purchase.updatedAt),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "${'purchase-info.total'.tr()} - ",
                  style: titleStyle,
                ),
                Flexible(
                  child: Text(
                    (displayCurrency == widget.purchase.currency ? widget.purchase.amount : widget.purchase.amount).toMoneyString(
                      displayCurrency,
                      withSymbol: true,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Visibility(
              visible: widget.purchase.currency != groupCurrency,
              child: Table(
                  columnWidths: {
                    0: FlexColumnWidth(1),
                    1: FixedColumnWidth(60),
                    2: FlexColumnWidth(1),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        Center(
                          child: Text(
                            'info.purchase-currency'.tr(namedArgs: {"currency": widget.purchase.currency.code}),
                            style: titleStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Center(
                          child: Switch(
                            value: displayCurrency == groupCurrency,
                            onChanged: (value) => setState(() {
                              displayCurrency = value ? groupCurrency : widget.purchase.currency;
                            }),
                          ),
                        ),
                        Center(
                          child: Text(
                            'info.group-currency'.tr(
                              namedArgs: {"currency": groupCurrency.code},
                            ),
                            style: titleStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ]),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GradientButton.icon(
                  onPressed: () async {
                    bool? edited = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (context) => PurchasePage(purchase: widget.purchase)),
                    );
                    if (edited ?? false) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(Icons.edit),
                  label: Text('modify'.tr()),
                ),
                GradientButton.icon(
                  onPressed: () {
                    showDialog(
                      builder: (context) => ConfirmChoiceDialog(
                        choice: 'confirm-delete',
                      ),
                      context: context,
                    ).then((value) {
                      if (value != null && value) {
                        showFutureOutputDialog(context: context, future: _deleteElement(widget.purchase.id), outputCallbacks: {
                          BoolFutureOutput.True: () {
                            Navigator.pop(context);
                            Navigator.pop(context, true); // Refresh the list
                          }
                        });
                      }
                    });
                  },
                  icon: Icon(Icons.delete),
                  label: Text('delete'.tr()),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
