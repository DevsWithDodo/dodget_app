import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:flutter/material.dart';


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

  // Helper method to format DateTime to YYYY.MM.DD
  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  // Helper method to parse YYYY.MM.DD to DateTime
  static DateTime _parseDate(String dateString) {
    final parts = dateString.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid date format: $dateString. Expected YYYY.MM.DD');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'date': _formatDate(date), // Store as YYYY.MM.DD
      'currency': currency.code,
      'category_id': categoryId,
      'recurring_months': recurringMonths,
      'recurring_until': recurringUntil != null ? _formatDate(recurringUntil!) : null,
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    // Helper to parse numeric values that might be stored as strings
    double parsePrice(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        // Replace comma with period for European decimal format
        String normalized = value.replaceAll(',', '.');
        return double.parse(normalized);
      }
      throw FormatException('Invalid price format: $value');
    }
    
    int parseCategoryId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.parse(value);
      throw FormatException('Invalid category_id format: $value');
    }
    
    int? parseRecurringMonths(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.parse(value);
      throw FormatException('Invalid recurring_months format: $value');
    }
    
    return Transaction(
      id: map['id'],
      name: map['name'] ?? '',
      price: parsePrice(map['price']),
      date: _parseDate(map['date']),
      currency: Currency.fromCode(map['currency']),
      categoryId: parseCategoryId(map['category_id']),
      recurringMonths: parseRecurringMonths(map['recurring_months']),
      recurringUntil: map['recurring_until'] != null ? _parseDate(map['recurring_until']) : null,
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
    // Helper to parse id that might be stored as string
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.parse(value);
      throw FormatException('Invalid id format: $value');
    }
    
    return CategoryModel(
      id: parseId(map['id']),
      name: map['name'],
    );
  }

  @override
  String toString() {
    return 'CategoryModel{id: $id, name: $name}';
  }
}
