import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AppSettings {
  Currency currency;
  bool ratedApp;
  bool showAds;
  bool useGradients;
  bool personalisedAds;
  bool trialVersion;

  AppSettings({
    required this.currency,
    this.ratedApp = false,
    this.showAds = false,
    this.useGradients = true,
    this.personalisedAds = false,
    this.trialVersion = false,
  });
}

class Group {
  Currency currency;
  String name;
  int id;
  bool? adminApproval;
  Group({
    required this.name,
    required this.id,
    required this.currency,
    this.adminApproval,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      name: json['group_name'],
      id: json['group_id'],
      currency: Currency.fromCode(json['currency']),
    );
  }
}

class Purchase {
  int id;
  double amount;
  String name;
  Currency currency;
  DateTime updatedAt;
  Category category;

  Purchase({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.updatedAt,
    required this.category,
  }) {
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['purchase_id'],
      name: json['name'],
      updatedAt: json['updated_at'] == null ? DateTime.now() : DateTime.parse(json['updated_at']).toLocal(),
      currency: Currency.fromCode(json['original_currency']),
      amount: (json['total_amount'] * 1.0),
      category: Category.fromName(json["category"]),
    );
  }

  factory Purchase.example(String name, double amount, Currency currency, Category category) {
    return Purchase(
      id: 0,
      name: name,
      updatedAt: DateTime.now(),
      currency: currency,
      amount: amount,
      category: category
    );
  }
}

class Payment {
  int id;
  double amount;
  late double amountOriginalCurrency;
  DateTime updatedAt;
  String payerUsername, payerNickname, takerUsername, takerNickname;
  late String note;
  int payerId, takerId;
  Currency originalCurrency;

  Payment({
    required this.id,
    required this.amount,
    double? amountOriginalCurrency,
    required this.payerUsername,
    required this.payerId,
    required this.payerNickname,
    required this.takerUsername,
    required this.takerId,
    required this.takerNickname,
    String? note,
    required this.originalCurrency,
    required this.updatedAt,
  }) {
    this.amountOriginalCurrency = amountOriginalCurrency ?? this.amount;
    this.note = note ?? '';
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['payment_id'],
      amount: (json['amount'] * 1.0),
      updatedAt: json['updated_at'] == null ? DateTime.now() : DateTime.parse(json['updated_at']).toLocal(),
      payerId: json['payer_id'],
      payerUsername: json['payer_username'] ?? json['payer_nickname'],
      payerNickname: json['payer_nickname'],
      takerId: json['taker_id'],
      takerUsername: json['taker_username'] ?? json['taker_nickname'],
      takerNickname: json['taker_nickname'],
      note: json['note'],
      originalCurrency: Currency.fromCode(json['original_currency']),
      amountOriginalCurrency: (json['original_amount'] ?? json['amount']) * 1.0,
    );
  }
}

enum CategoryType {
  food,
  groceries,
  transport,
  entertainment,
  shopping,
  health,
  bills,
  other,
}

class Category {
  CategoryType type;
  IconData icon;
  String text;
  Category({required this.type, required this.icon, required this.text});

  String tr() {
    return "categories.$text".tr();
  }

  static Category fromName(String categoryName) {
    return Category.categories.firstWhere((category) => category.text == categoryName);
  }

  static Category fromType(CategoryType type) {
    return Category.categories.firstWhere((category) => category.type == type);
  }

  static List<Category> categories = [
    Category(type: CategoryType.food, icon: Icons.fastfood, text: 'food'),
    Category(
      type: CategoryType.groceries,
      icon: Icons.shopping_basket,
      text: 'groceries',
    ),
    Category(type: CategoryType.transport, icon: Icons.train, text: 'transport'),
    Category(
      type: CategoryType.entertainment,
      icon: Icons.movie_filter,
      text: 'entertainment',
    ),
    Category(
      type: CategoryType.shopping,
      icon: Icons.shopping_bag,
      text: 'shopping',
    ),
    Category(
      type: CategoryType.health,
      icon: Icons.health_and_safety,
      text: 'health',
    ),
    Category(type: CategoryType.bills, icon: Icons.house, text: 'bills'),
    Category(type: CategoryType.other, icon: Icons.category, text: 'other'),
  ];

  @override
  bool operator ==(Object other) => identical(this, other) || other is Category && runtimeType == other.runtimeType && type == other.type && icon == other.icon && text == other.text;
}


class ReceiptInformation {
  File imageFile;
  String storeName;
  Currency currency;
  List<ReceiptItem> items;

  ReceiptInformation({
    required this.imageFile,
    required this.storeName,
    required this.currency,
    required this.items,
  });

  double get totalCost => this.items.fold(0, (prev, current) => prev + current.cost);

  factory ReceiptInformation.fromJson(Map<String, dynamic> json, File imageFile) {
    json['items'] = (json['items'] as List<dynamic>).map((item) => item as Map<String, dynamic>).toList();
    var groupedByName = groupBy(json['items'] as List<Map<String, dynamic>>, (Map<String, dynamic> item) => item['item_name']).values.toList();
    List<List<Map<String, dynamic>>> groupedByNameCost = [];
    for (var group in groupedByName) {
      var groupedByCost = groupBy(group, (Map<String, dynamic> item) => item['cost']).values.toList();
      for (var groupCost in groupedByCost) {
        groupedByNameCost.add(groupCost);
      }
    }

    List<ReceiptItem> items = groupedByNameCost.map<ReceiptItem>((group) {
      var item = group.first;
      item['cost'] *= group.length; // Same cost items are grouped together
      item['discount'] *= group.length;
      return ReceiptItem.fromJson(item);
    }).toList();

    return ReceiptInformation(
      storeName: json['store_name'],
      currency: Currency.fromCodeSafe(json['currency_code_iso_4217']),
      items: items,
      imageFile: imageFile,
    );
  }

  factory ReceiptInformation.dummy(File imageFile) {
    return ReceiptInformation(
      storeName: 'Dummy Store',
      currency: Currency.fromCode('HUF'),
      items: [
        ReceiptItem(itemName: 'Item 1', baseCost: 100000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 2', baseCost: 200000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 3', baseCost: 300000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 4', baseCost: 400000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 5', baseCost: 500000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 6', baseCost: 600000, discount: 0, assignedAmounts: {}),
      ],
      imageFile: imageFile,
    );
  }
}

class ReceiptItem {
  String itemName;
  double baseCost;
  double discount;
  double cost;

  /// Map from member id to amount assigned to that member
  Map<int, int> assignedAmounts = {};

  ReceiptItem({
    required this.itemName,
    required this.baseCost,
    required this.discount,
    required this.assignedAmounts,
  }) : cost = baseCost - discount;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: json['item_name'],
      baseCost: json['cost'] * 1.0,
      discount: ((json['discount'] ?? 0) as num).abs() * 1.0,
      assignedAmounts: {},
    );
  }
}
