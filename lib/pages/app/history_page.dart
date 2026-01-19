import 'package:csocsort_szamla/helpers/models.dart' as models;
import 'package:csocsort_szamla/helpers/repository.dart';
import 'package:csocsort_szamla/pages/app/transaction_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  HistoryPage();

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  Future<List<models.Transaction>>? _transactions;
  Future<List<models.Transaction>>? _recurringTransactions;

  TabController? _tabController;
  Map<int, models.CategoryModel> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    final categoryRepo = context.read<CategoryRepository>();
    final cats = await categoryRepo.list();
    setState(() {
      for (var cat in cats) {
        _categoryMap[cat.id] = cat;
      }
    });
  }

  void _loadTransactions() {
    final transactionRepo = context.read<TransactionRepository>();
    setState(() {
      _transactions = transactionRepo.list();
      _recurringTransactions = transactionRepo.getRecurringTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Transactions', icon: Icon(Icons.list)),
            Tab(text: 'Recurring', icon: Icon(Icons.repeat)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTransactionsList(),
          _buildRecurringTransactionsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionPage(),
            ),
          );
          if (result == true) {
            _loadTransactions();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAllTransactionsList() {
    return FutureBuilder<List<models.Transaction>>(
      future: _transactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading transactions'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No transactions yet'),
              ],
            ),
          );
        }

        final transactions = snapshot.data!;
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final category = _categoryMap[transaction.categoryId];
            return _buildTransactionCard(transaction, category);
          },
        );
      },
    );
  }

  Widget _buildRecurringTransactionsList() {
    return FutureBuilder<List<models.Transaction>>(
      future: _recurringTransactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading recurring transactions'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.repeat, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No recurring transactions'),
              ],
            ),
          );
        }

        final transactions = snapshot.data!;
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final category = _categoryMap[transaction.categoryId];
            return _buildTransactionCard(transaction, category, showRecurring: true);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(models.Transaction transaction, models.CategoryModel? category, {bool showRecurring = false}) {
    final isIncome = transaction.price < 0;
    final absPrice = transaction.price.abs();
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green : Colors.red,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${category?.name ?? 'Unknown'} • ${DateFormat('yyyy-MM-dd').format(transaction.date)}'),
            if (showRecurring && transaction.recurringMonths != null)
              Text(
                'Every ${transaction.recurringMonths} month(s)${transaction.recurringUntil != null ? ' until ${DateFormat('yyyy-MM-dd').format(transaction.recurringUntil!)}' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${absPrice.toStringAsFixed(2)} ${transaction.currency.code}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        onTap: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionPage(transaction: transaction),
            ),
          );
          if (result == true) {
            _loadTransactions();
          }
        },
      ),
    );
  }
}
