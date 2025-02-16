import 'package:collection/collection.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:flutter/material.dart';

class AmountDivision {
  List<PurchaseReceiver> amounts;
  double totalAmount = 0;
  Currency currency;
  VoidCallback setState;

  AmountDivision({
    required this.amounts,
    required this.currency,
    required this.setState,
    this.totalAmount = 0,
  });

  List<int> get memberIds => amounts.map((e) => e.memberId).toList();

  List<PurchaseReceiver> get customAmounts => amounts.where((element) => element.isCustomAmount).toList();

  List<PurchaseReceiver> get calculatedAmounts => amounts.where((element) => !element.isCustomAmount).toList();

  PurchaseReceiver get firstCustomized => customAmounts.sorted((a, b) => a.customizedAt!.compareTo(b.customizedAt!)).first;

  factory AmountDivision.fromPurchase(Purchase purchase, VoidCallback setState) {
    AmountDivision amountDivision = AmountDivision(
      amounts: [],
      currency: purchase.currency,
      setState: setState,
      totalAmount: purchase.amount,
    );
    return amountDivision;
  }

  factory AmountDivision.fromReceiptInformation(ReceiptInformation information, VoidCallback setState) {
    final totalAmount = information.items
        .where(
          (element) => element.assignedAmounts.isNotEmpty,
        )
        .map((e) => e.cost)
        .fold(0.0, (previousValue, element) => previousValue + element);
    AmountDivision amountDivision = AmountDivision(
      amounts: [],
      currency: information.currency,
      setState: setState,
      totalAmount: totalAmount,
    );

    return amountDivision;
  }

  bool isValid([bool setErrors = false]) {
    final invalidAmounts = amounts.where((element) => element.parsedAmount == null || element.parsedAmount! <= 0);
    if (invalidAmounts.isNotEmpty) {
      if (setErrors) {
        for (PurchaseReceiver amount in invalidAmounts) {
          amount.error = true;
        }
        setState();
      }
      return false;
    }

    if (amounts.where((element) => element.parsedAmount! > totalAmount).isNotEmpty) {
      return false;
    }

    if (customAmounts.total() > totalAmount) {
      return false;
    }

    return true;
  }

  void addMember(int memberId, String memberNickname, [bool rebuild = true]) {
    if (totalAmount == 0) {
      amounts.add(PurchaseReceiver.fromMember(
        memberId,
        memberNickname,
        () => setAmount(memberId, false),
        () => setAmount(memberId, true),
        () => resetCustom(memberId),
      ));
      if (rebuild) setState();
      return;
    }
    double totalSetAmount = customAmounts.total();
    double amountPerMember = (totalAmount - totalSetAmount) / (calculatedAmounts.length + 1);
    double percentagePerMember = amountPerMember / totalAmount * 100;
    for (PurchaseReceiver memberAmount in calculatedAmounts) {
      memberAmount.customAmountController.text = amountPerMember.toMoneyString(currency);
      memberAmount.percentageController.text = percentagePerMember.toInt().toString();
    }
    amounts.add(PurchaseReceiver.fromMember(
      memberId,
      memberNickname,
      () => setAmount(memberId, false),
      () => setAmount(memberId, true),
      () => resetCustom(memberId),
    ));
    amounts.last.customAmountController.text = amountPerMember.toMoneyString(currency);
    amounts.last.percentageController.text = percentagePerMember.toInt().toString();

    setState();
  }

  void removeMember(int memberId) {
    amounts.removeWhere((element) => element.memberId == memberId);
    if (totalAmount == 0) {
      setState();
      return;
    }
    if (amounts.isEmpty) return;
    if (calculatedAmounts.isNotEmpty) {
      double totalSetAmount = customAmounts.total();
      double amountPerMember = (totalAmount - totalSetAmount) / calculatedAmounts.length;
      double percentagePerMember = amountPerMember / totalAmount * 100;
      for (PurchaseReceiver memberAmount in calculatedAmounts) {
        memberAmount.customAmountController.text = amountPerMember.toMoneyString(currency);
        memberAmount.percentageController.text = percentagePerMember.toInt().toString();
      }
    }
    // The removed member was the only one without a custom amount
    else {
      double totalSetAmount = customAmounts.where((element) => element.memberId != firstCustomized.memberId).total();
      double amountPerMember = (totalAmount - totalSetAmount);
      firstCustomized.customAmountController.text = amountPerMember.toMoneyString(currency);
      firstCustomized.percentageController.text = (amountPerMember / totalAmount * 100).toInt().toString();
      firstCustomized.customizedAt = null;
    }
    setState();
  }

  void setTotal(double total) {
    totalAmount = total;
    for (PurchaseReceiver memberAmount in customAmounts) {
      if (memberAmount.customizedThroughAmount) {
        memberAmount.percentageController.text = ((memberAmount.parsedAmount ?? 0) / total * 100).toInt().toString();
      } else {
        memberAmount.customAmountController.text = (total * (memberAmount.parsedPercentage ?? 0) / 100).toMoneyString(currency);
      }
    }
    double amountPerMember = (total - customAmounts.total()) / calculatedAmounts.length;
    double percentagePerMember = amountPerMember / total * 100;
    for (PurchaseReceiver memberAmount in calculatedAmounts) {
      memberAmount.customAmountController.text = amountPerMember.toMoneyString(currency);
      memberAmount.percentageController.text = percentagePerMember.toInt().toString();
    }
    setState();
  }

  void setCurrency(Currency newCurrency) {
    currency = newCurrency;
    for (PurchaseReceiver memberAmount in amounts) {
      memberAmount.customAmountController.text = memberAmount.parsedAmount!.toMoneyString(currency);
    }
    setState();
  }

  void resetCustom(int forMemberId) {
    PurchaseReceiver forAmount = amounts.firstWhere((element) => element.memberId == forMemberId);
    forAmount.customizedAt = null;
    double amountPerMember = (totalAmount - customAmounts.total()) / calculatedAmounts.length;
    for (PurchaseReceiver memberAmount in calculatedAmounts) {
      memberAmount.customAmountController.text = amountPerMember.toMoneyString(currency);
      memberAmount.percentageController.text = ((amountPerMember / totalAmount) * 100).toInt().toString();
    }
    setState();
  }

  void resetAll() {
    double amountPerMember = totalAmount / amounts.length;
    double percentagePerMember = amountPerMember / totalAmount * 100;
    for (PurchaseReceiver memberAmount in amounts) {
      memberAmount.customizedAt = null;
      memberAmount.customAmountController.text = amountPerMember.toMoneyString(currency);
      memberAmount.percentageController.text = percentagePerMember.toInt().toString();
    }
    setState();
  }

  void setAmount(int forMemberId, bool fromPercentage) {
    PurchaseReceiver forReceiver = amounts.firstWhere((element) => element.memberId == forMemberId);
    double amount = fromPercentage ? ((forReceiver.parsedPercentage ?? 0) / 100) * totalAmount : (forReceiver.parsedAmount ?? 0);
    double previousAmount = totalAmount - amounts.where((element) => element.memberId != forMemberId).total();
    if (amount == previousAmount) return;
    if (amount >= totalAmount) {
      amount = totalAmount - (amounts.length - 1) * currency.smallestUnit;
    }
    forReceiver.customizedAt = DateTime.now();
    while ((calculatedAmounts.total() + previousAmount - calculatedAmounts.length * currency.smallestUnit) < amount) {
      firstCustomized.customizedAt = null;
    }

    forReceiver.customAmountController.text = amount.toMoneyString(currency);
    forReceiver.percentageController.text = ((amount / totalAmount) * 100).toInt().toString();

    if (calculatedAmounts.isEmpty) {
      firstCustomized.customizedAt = null;
    }
    double amountPerMember = (totalAmount - customAmounts.total()) / calculatedAmounts.length;
    for (PurchaseReceiver memberAmount in calculatedAmounts) {
      memberAmount.customAmountController.text = amountPerMember.toMoneyString(currency);
      memberAmount.percentageController.text = ((amountPerMember / totalAmount) * 100).toInt().toString();
    }
    setState();
  }

  List<Map<String, num?>> generateReceivers(bool useCustomAmounts) {
    return amounts
        .map((amount) => {
              "user_id": amount.memberId,
              "amount": (useCustomAmounts && amount.isCustomAmount) ? amount.parsedAmount : null,
            })
        .toList();
  }
}

extension on Iterable<PurchaseReceiver> {
  double total() => this.fold(
        0,
        (previousValue, element) => previousValue + (double.tryParse(element.customAmountController.text) ?? 0),
      );
}

class PurchaseReceiver {
  int memberId;
  String memberNickname;
  TextEditingController customAmountController;
  TextEditingController percentageController;
  DateTime? customizedAt;
  bool customizedThroughAmount = true;
  VoidCallback setAmount;
  VoidCallback setPercentage;
  VoidCallback resetCustom;
  bool error = false;

  PurchaseReceiver({
    required this.memberId,
    required this.customAmountController,
    required this.percentageController,
    required this.setAmount,
    required this.setPercentage,
    required this.resetCustom,
    required this.memberNickname,
    this.customizedAt,
  });

  factory PurchaseReceiver.fromMember(
    int memberId,
    String nickname,
    VoidCallback setAmount,
    VoidCallback setPercentage,
    VoidCallback resetCustom,
  ) {
    return PurchaseReceiver(
      memberId: memberId,
      memberNickname: nickname,
      customAmountController: TextEditingController(),
      percentageController: TextEditingController(),
      setAmount: setAmount,
      setPercentage: setPercentage,
      resetCustom: resetCustom,
    );
  }

  double? get parsedAmount => double.tryParse(customAmountController.text.replaceAll(',', '.'));
  int? get parsedPercentage => int.tryParse(percentageController.text.replaceAll(',', '.'));
  bool get isCustomAmount => customizedAt != null;

  void handleSetAmount() {
    if (parsedAmount != null) {
      customizedThroughAmount = true;
      error = false;
      setAmount();
    }
  }

  void handleSetPercentage() {
    if (parsedPercentage != null && parsedPercentage! > 0 && parsedPercentage! < 100) {
      customizedThroughAmount = false;
      error = false;
      setPercentage();
    }
  }
}
