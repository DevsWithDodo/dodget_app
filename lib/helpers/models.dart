import 'package:csocsort_szamla/helpers/currencies.dart';
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

class Transaction {
  int? id;
  double price;
  String name;
  Currency currency;
  DateTime date;
  int categoryId;
  int? recurringMonths;
  DateTime? recurringUntil;

  Transaction({
    this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.date,
    required this.categoryId,
    this.recurringMonths,
    this.recurringUntil,
  });

  bool get isIncome => price < 0;
  bool get isExpense => price > 0;
  bool get isRecurring => recurringMonths != null;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'date': date.toIso8601String().split('T')[0], // Store as YYYY-MM-DD
      'currency': currency.code,
      'category_id': categoryId,
      'recurring_months': recurringMonths,
      'recurring_until': recurringUntil?.toIso8601String().split('T')[0],
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      currency: Currency.fromCode(map['currency']),
      categoryId: map['category_id'],
      recurringMonths: map['recurring_months'],
      recurringUntil: map['recurring_until'] != null ? DateTime.parse(map['recurring_until']) : null,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, name: $name, price: $price, currency: $currency, date: $date, categoryId: $categoryId, recurringMonths: $recurringMonths}';
  }

  factory Transaction.example(String name, double price, Currency currency, int categoryId) {
    return Transaction(
      id: null,
      name: name,
      date: DateTime.now(),
      currency: currency,
      price: price,
      categoryId: categoryId,
    );
  }
}

class CategoryModel {
  int id;
  String name;

  CategoryModel({
    required this.id,
    required this.name,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  static CategoryModel fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
    );
  }

  @override
  String toString() {
    return 'CategoryModel{id: $id, name: $name}';
  }
}
