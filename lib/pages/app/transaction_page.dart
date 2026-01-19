import 'dart:async';

import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart' as models;
import 'package:csocsort_szamla/helpers/repository.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/web.dart';
import 'package:provider/provider.dart';

class TransactionPage extends StatefulWidget {
  final models.Transaction? transaction;

  TransactionPage({this.transaction});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  _TransactionPageState() : super();

  var _formKey = GlobalKey<FormState>();

  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController recurringMonthsController = TextEditingController();
  Currency selectedCurrency = Currency.fromCode('DKK');
  models.CategoryModel? selectedCategory;
  DateTime date = DateTime.now();
  bool isExpense = true; // true = expense, false = income
  bool isRecurring = false;
  DateTime? recurringUntil;
  
  List<models.CategoryModel> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (widget.transaction != null) {
      noteController.text = widget.transaction!.name;
      double absAmount = widget.transaction!.price.abs();
      amountController.text = absAmount.toMoneyString(widget.transaction!.currency);
      selectedCurrency = widget.transaction!.currency;
      date = widget.transaction!.date;
      isExpense = widget.transaction!.price > 0;
      isRecurring = widget.transaction!.isRecurring;
      if (widget.transaction!.recurringMonths != null) {
        recurringMonthsController.text = widget.transaction!.recurringMonths.toString();
      }
      recurringUntil = widget.transaction!.recurringUntil;
    }
    dateController.text = DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadCategories() async {
    final categoryRepo = context.read<CategoryRepository>();
    final loadedCategories = await categoryRepo.list();
    setState(() {
      categories = loadedCategories;
      if (widget.transaction != null) {
        selectedCategory = categories.firstWhere(
          (cat) => cat.id == widget.transaction!.categoryId,
          orElse: () => categories.first,
        );
      } else {
        selectedCategory = categories.isNotEmpty ? categories.first : null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: widget.transaction != null
              ? [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context),
                  ),
                ]
              : null,
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
                          // Income/Expense Toggle
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(
                                value: true,
                                label: Text('Expense'),
                                icon: Icon(Icons.arrow_upward),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('Income'),
                                icon: Icon(Icons.arrow_downward),
                              ),
                            ],
                            selected: {isExpense},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                isExpense = newSelection.first;
                              });
                            },
                          ),
                          SizedBox(height: 20),
                          
                          // Transaction Name
                          TextFormField(
                            validator: (value) => validateTextField([
                              isEmpty(value),
                            ]),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(
                                Icons.note,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            inputFormatters: [LengthLimitingTextInputFormatter(50)],
                            controller: noteController,
                            onFieldSubmitted: (value) => submit(context),
                          ),
                          SizedBox(height: 20),
                          
                          // Category Dropdown
                          DropdownButtonFormField<models.CategoryModel>(
                            value: selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(
                                Icons.category,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            items: categories.map((models.CategoryModel category) {
                              return DropdownMenuItem<models.CategoryModel>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: (models.CategoryModel? newCategory) {
                              setState(() {
                                selectedCategory = newCategory;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          
                          // Amount Row
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: selectedCurrency.code,
                                  decoration: InputDecoration(labelText: 'Currency'),
                                  items: Currency.all().map((currency) {
                                    return DropdownMenuItem(
                                      value: currency.code,
                                      child: Text(currency.code),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() {
                                    if (value != null) {
                                      selectedCurrency = Currency.fromCode(value);
                                    }
                                  }),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  validator: (value) => validateTextField([
                                    isEmpty(value),
                                    notValidNumber(value!.replaceAll(',', '.')),
                                  ]),
                                  decoration: InputDecoration(labelText: 'Amount'),
                                  controller: amountController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
                                  onFieldSubmitted: (value) => submit(context),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // Date Picker
                          TextFormField(
                            controller: dateController,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  date = pickedDate;
                                  dateController.text = DateFormat('yyyy-MM-dd').format(date);
                                });
                              }
                            },
                          ),
                          SizedBox(height: 20),
                          
                          // Recurring Transaction Toggle
                          SwitchListTile(
                            title: Text('Recurring Transaction'),
                            value: isRecurring,
                            onChanged: (bool value) {
                              setState(() {
                                isRecurring = value;
                                if (!value) {
                                  recurringMonthsController.clear();
                                  recurringUntil = null;
                                }
                              });
                            },
                          ),
                          
                          // Recurring Options
                          if (isRecurring) ...[
                            SizedBox(height: 10),
                            TextFormField(
                              controller: recurringMonthsController,
                              decoration: InputDecoration(
                                labelText: 'Repeat Every X Months',
                                prefixIcon: Icon(
                                  Icons.repeat,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (isRecurring && (value == null || value.isEmpty)) {
                                  return 'Please enter recurring months';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Recurring Until (Optional)',
                                prefixIcon: Icon(
                                  Icons.event,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: recurringUntil != null
                                    ? DateFormat('yyyy-MM-dd').format(recurringUntil!)
                                    : '',
                              ),
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: recurringUntil ?? date.add(Duration(days: 365)),
                                  firstDate: date,
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    recurringUntil = pickedDate;
                                  });
                                }
                              },
                            ),
                          ],
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
      ),
    );
  }

  Future<void> submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      
      double amount = double.tryParse(amountController.value.text.replaceAll(',', '.')) ?? 0.0;
      // Negate amount if it's income
      if (!isExpense) {
        amount = -amount;
      }
      
      models.Transaction newTransaction = models.Transaction(
        id: widget.transaction?.id,
        name: noteController.text,
        price: amount,
        currency: selectedCurrency,
        date: date,
        categoryId: selectedCategory!.id,
        recurringMonths: isRecurring ? int.tryParse(recurringMonthsController.text) : null,
        recurringUntil: isRecurring ? recurringUntil : null,
      );

      try {
        await _saveTransaction(widget.transaction, newTransaction);
        if (context.mounted) {
          Navigator.pop(context);
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving transaction: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveTransaction(models.Transaction? oldTransaction, models.Transaction newTransaction) async {
    try {
      var logger = Logger();
      logger.d("saving transaction: $newTransaction");
      final transactionRepo = context.read<TransactionRepository>();

      if (oldTransaction == null) {
        await transactionRepo.insert(newTransaction);
      } else {
        await transactionRepo.update(newTransaction);
      }
    } catch (e) {
      throw e;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTransaction(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    if (widget.transaction?.id != null) {
      try {
        final transactionRepo = context.read<TransactionRepository>();
        await transactionRepo.delete(widget.transaction!.id!);
        if (context.mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaction deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaction')),
          );
        }
      }
    }
  }
}
