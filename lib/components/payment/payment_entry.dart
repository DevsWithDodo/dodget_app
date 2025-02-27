import 'package:csocsort_szamla/components/payment/payment_all_info.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentEntry extends StatefulWidget {
  final Payment payment;
  final int? selectedMemberId;

  PaymentEntry({
    required this.payment,
    this.selectedMemberId,
  });

  @override
  _PaymentEntryState createState() => _PaymentEntryState();
}

class _PaymentEntryState extends State<PaymentEntry> {

  @override
  void initState() {
    super.initState();
  }

  void handleSendReaction(String reaction) {
  }

  @override
  Widget build(BuildContext context) {
    ThemeName themeName = context.watch<AppThemeState>().themeName;
    bool paid = true;
    Color textColor = themeName.type == ThemeType.gradient
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimaryContainer;
    String note = (widget.payment.note == '')
        ? 'no_note'.tr()
        : widget.payment.note[0].toUpperCase() + widget.payment.note.substring(1);
    String takerName = paid ? widget.payment.takerNickname : widget.payment.payerNickname;
    String amount = (paid ? '' : '-') +
        widget.payment.amountOriginalCurrency.toMoneyString(widget.payment.originalCurrency, withSymbol: true);
    BoxDecoration boxDecoration = paid
        ? BoxDecoration(
            gradient: AppTheme.gradientFromTheme(themeName, usePrimaryContainer: true),
            borderRadius: BorderRadius.circular(15),
          )
        : BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(15),
          );

    TextStyle mainTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(color: textColor);
    TextStyle subTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColor);
    Widget buyer = Row(
      children: [
        Icon(
          paid ? Icons.call_made : Icons.call_received,
          color: textColor,
          size: 11,
        ),
        SizedBox(width: 2),
        Text(
          paid ? 'payment-entry.paid'.tr() : 'payment-entry.received'.tr(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: textColor,
                fontSize: 9.5,
              ),
        ),
      ],
    );
    return Stack(
      children: [
        Container(
          decoration: boxDecoration,
          margin: EdgeInsets.only(
            top: 0,
            bottom: 4,
            left: 4,
            right: 4,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () async {
                final value = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SingleChildScrollView(
                    child: PaymentAllInfo(
                      widget.payment,
                      handleSendReaction,
                    ),
                  ),
                );
                if (value == 'deleted') {
                  final bus = EventBus.instance;
                  bus.fire(EventBus.refreshPayments);
                  bus.fire(EventBus.refreshBalances);
                }
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buyer,
                          Flexible(
                            child: Text(
                              takerName,
                              style: mainTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              note,
                              style: subTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ),
                    Text(
                      amount,
                      style: mainTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
