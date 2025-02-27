import 'dart:async';

import 'package:csocsort_szamla/components/helpers/calculator.dart';
import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/repository.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/web.dart';
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

  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  late Currency selectedCurrency;
  Category? selectedCategory;
  late int purchaserId;
  DateTime date = DateTime.now();
  CrossFadeState purchaserCrossFadeState = CrossFadeState.showFirst;
  bool saveInitialized = false;

  GlobalKey _noteKey = GlobalKey();
  GlobalKey _currencyKey = GlobalKey();
  GlobalKey _calculatorKey = GlobalKey();

  ReceiptInformation? receiptInformation;

  @override
  void initState() {
    super.initState();
    selectedCurrency = context.read<UserState>().group!.currency;

    if (widget.purchase != null) {
      noteController.text = widget.purchase!.name;
      amountController.text = widget.purchase!.amount.toMoneyString(widget.purchase!.currency);
      selectedCurrency = widget.purchase!.currency;
      selectedCategory = widget.purchase!.category;
      date = widget.purchase!.date;
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
                          SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Icon(Icons.send, color: Theme.of(context).colorScheme.onTertiary),
          onPressed: () => submit(context),
        ),
      )
    );
  }

  void submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      Purchase newPurchase = Purchase(
        id: -1, 
        name: noteController.text, 
        amount: double.tryParse(amountController.value.text) ?? 0.0,
        currency: selectedCurrency, 
        date: date,
        category: selectedCategory ?? Category.fromName('other')
      );

      showFutureOutputDialog(
        context: context,
        future: _insertPurchase(widget.purchase, newPurchase),
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

  Future<BoolFutureOutput> _insertPurchase(Purchase? oldPurchase, Purchase newPurchase) async {
    try {
      var logger = Logger();
      logger.d("inserting purchase: $newPurchase");
      final purchaseRepo = context.read<PurchaseRepository>();

      if(oldPurchase == null){
        await purchaseRepo.insert(newPurchase);
        return BoolFutureOutput.True;
      } else {
        return BoolFutureOutput.False;
      }
    } catch (_) {
      throw _;
    }
  }
}
