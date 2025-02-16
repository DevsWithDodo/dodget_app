import 'dart:async';
import 'dart:convert';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/calculator.dart';
import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/custom_choice_chip.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/purchase/custom_amount_field.dart';
import 'package:csocsort_szamla/helpers/amount_division.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class PurchasePage extends StatefulWidget {
  final Purchase? purchase;

  PurchasePage({this.purchase});

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  _PurchasePageState() : super();

  var _formKey = GlobalKey<FormState>();
  ExpandableController _expandableController = ExpandableController();
  bool useCustomAmounts = false;

  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  late AmountDivision amountDivision;
  late Currency selectedCurrency;
  Category? selectedCategory;
  late int purchaserId;
  CrossFadeState purchaserCrossFadeState = CrossFadeState.showFirst;
  bool saveInitialized = false;

  GlobalKey _noteKey = GlobalKey();
  GlobalKey _currencyKey = GlobalKey();
  GlobalKey _calculatorKey = GlobalKey();

  ReceiptInformation? receiptInformation;

  Future<BoolFutureOutput> _postPurchase() async {
    try {
      Map<String, dynamic> body = {
        "name": noteController.text,
        "group": context.read<UserState>().group!.id,
        "amount": amountDivision.totalAmount,
        "currency": selectedCurrency,
        "category": selectedCategory != null ? selectedCategory!.text : null,
        "buyer_id": purchaserId,
        "receivers": amountDivision.generateReceivers(useCustomAmounts),
      };
      if (widget.purchase != null) {
        await Http.put(uri: '/purchases/${widget.purchase!.id}', body: body);
      } else {
        await Http.post(uri: '/purchases', body: body);
      }
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    selectedCurrency = context.read<UserState>().group!.currency;
    amountDivision = AmountDivision(
      amounts: [],
      currency: selectedCurrency,
      setState: () => setState(() {}),
    );

    if (widget.purchase != null) {
      noteController.text = widget.purchase!.name;
      amountController.text = widget.purchase!.amount.toMoneyString(widget.purchase!.currency);
      selectedCurrency = widget.purchase!.currency;
      selectedCategory = widget.purchase!.category;
      amountDivision = AmountDivision.fromPurchase(widget.purchase!, () => setState(() {}));
      useCustomAmounts = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('showcase_add_purchase') && prefs.getBool('showcase_add_purchase')!) {
        return;
      }
      ShowCaseWidget.of(context).startShowCase([_noteKey, _currencyKey, _calculatorKey]);
      prefs.setBool('showcase_add_purchase', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.purchase != null ? 'purchase.modify' : 'purchase',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ).tr(),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  validator: (value) => validateTextField([
                                    isEmpty(value),
                                  ]),
                                  decoration: InputDecoration(
                                    labelText: 'note'.tr(),
                                    prefixIcon: Icon(
                                      Icons.note,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                                  controller: noteController,
                                  onFieldSubmitted: (value) => submit(context),
                                ),
                              ),
                              Showcase(
                                key: _noteKey,
                                showArrow: false,
                                targetBorderRadius: BorderRadius.circular(10),
                                targetPadding: EdgeInsets.all(0),
                                description: "pick_category".tr(),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: CategoryPickerIconButton(
                                    selectedCategory: selectedCategory,
                                    onCategoryChanged: (newCategory) {
                                      setState(() {
                                        if (selectedCategory?.type == newCategory?.type) {
                                          selectedCategory = null;
                                        } else {
                                          selectedCategory = newCategory;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                scaleAnimationDuration: Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Showcase(
                                key: _currencyKey,
                                showArrow: false,
                                targetBorderRadius: BorderRadius.circular(10),
                                targetPadding: EdgeInsets.all(0),
                                description: "pick_currency".tr(),
                                child: Padding(
                                  padding: EdgeInsets.only(right: 5),
                                  child: CurrencyPickerIconButton(
                                    selectedCurrency: selectedCurrency,
                                    onCurrencyChanged: (newCurrency) => setState(() {
                                      selectedCurrency = newCurrency ?? selectedCurrency;
                                      amountDivision.setCurrency(selectedCurrency);
                                    }),
                                  ),
                                ),
                                scaleAnimationDuration: Duration(milliseconds: 200),
                              ),
                              Expanded(
                                child: TextFormField(
                                  validator: (value) => validateTextField([
                                    isEmpty(value),
                                    notValidNumber(value!.replaceAll(',', '.')),
                                  ]),
                                  decoration: InputDecoration(labelText: 'full_amount'.tr()),
                                  controller: amountController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
                                  onFieldSubmitted: (value) => submit(context),
                                  onChanged: (value) => setState(() {
                                    double? parsedTotal = double.tryParse(value.replaceAll(',', '.'));
                                    if (parsedTotal != null && parsedTotal > 0) {
                                      amountDivision.setTotal(parsedTotal);
                                    }
                                  }),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: IconButton.filledTonal(
                                  isSelected: false,
                                  onPressed: () {
                                    showModalBottomSheet(
                                      isScrollControlled: true,
                                      context: context,
                                      builder: (context) {
                                        return SingleChildScrollView(
                                          child: Calculator(
                                            selectedCurrency: selectedCurrency,
                                            initialNumber: amountController.text,
                                            onCalculationReady: (String fromCalc) {
                                              setState(() {
                                                double? value = double.tryParse(fromCalc);
                                                amountController.text = (value ?? 0.0).toMoneyString(
                                                  selectedCurrency,
                                                );
                                                if (value != null && value > 0) {
                                                  amountDivision.setTotal(value);
                                                }
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: Showcase(
                                    key: _calculatorKey,
                                    showArrow: false,
                                    targetBorderRadius: BorderRadius.circular(10),
                                    targetPadding: EdgeInsets.all(10),
                                    description: "use_calculator".tr(),
                                    child: Icon(Icons.calculate),
                                    scaleAnimationDuration: Duration(milliseconds: 200),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'to_who'.plural(2),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  _expandableController.expanded = !_expandableController.expanded;
                                }),
                                icon: Icon(
                                  Icons.info_outline,
                                  color: _expandableController.expanded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Expandable(
                            controller: _expandableController,
                            collapsed: Container(),
                            expanded: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'add_purchase_explanation'.tr(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (!useCustomAmounts && amountDivision.amounts.isNotEmpty)
                            Center(
                              child: Text(
                                'per_person'.tr(
                                  args: [
                                    (amountDivision.totalAmount / amountDivision.amounts.length).toMoneyString(
                                      selectedCurrency,
                                      withSymbol: true,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'purchase.page.custom-amount.switch'.tr(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Switch(
                                value: useCustomAmounts,
                                onChanged: (value) {
                                  double? totalAmount = double.tryParse(amountController.text.replaceAll(',', '.'));
                                  if (totalAmount == null || totalAmount <= 0) {
                                    showToast('purchase.page.custom-amount.toast.no-amount-given'.tr());
                                    setState(() => useCustomAmounts = false);
                                    return;
                                  }
                                  setState(() => useCustomAmounts = value);
                                },
                              ),
                            ],
                          ),
                          if (useCustomAmounts)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 20),
                                child: Text(
                                  'purchase.page.custom-amount.hint'.tr(),
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                          AnimatedCrossFade(
                            crossFadeState: !useCustomAmounts ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            duration: Duration(milliseconds: 300),
                            firstChild: Container(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: amountDivision.amounts.map((PurchaseReceiver amount) {
                                return CustomAmountField(
                                  amount: amount,
                                  currency: selectedCurrency,
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: AdUnit(site: 'purchase'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Icon(Icons.send, color: Theme.of(context).colorScheme.onTertiary),
          onPressed: () => submit(context),
        ),
      ),
    );
  }

  void submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate() && (!useCustomAmounts || amountDivision.isValid(true))) {
      if (amountDivision.amounts.isEmpty) {
        FToast ft = FToast();
        ft.init(context);
        ft.showToast(
          child: errorToast('person_not_chosen', context),
          toastDuration: Duration(seconds: 2),
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }
      showFutureOutputDialog(
        context: context,
        future: _postPurchase(),
        outputCallbacks: {
          BoolFutureOutput.True: () {
            Navigator.pop(context);
            Navigator.pop(context, true); // True: Created/modified purchase
            final bus = EventBus.instance;
            bus.fire(EventBus.refreshBalances);
            bus.fire(EventBus.refreshPurchases);
          }
        },
      );
    }
  }
}
