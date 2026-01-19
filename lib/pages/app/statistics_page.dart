import 'package:csocsort_szamla/helpers/repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  StatisticsPage();

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Future<List<Map<String, dynamic>>>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadStatistics() {
    final transactionRepo = context.read<TransactionRepository>();
    setState(() {
      _statistics = transactionRepo.getStatDetailed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _statistics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading statistics'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No statistics available yet'),
                  SizedBox(height: 8),
                  Text('Add some transactions to see statistics'),
                ],
              ),
            );
          }

          final stats = snapshot.data!;
          
          // Group by month
          Map<String, List<Map<String, dynamic>>> groupedByMonth = {};
          for (var stat in stats) {
            String month = stat['month'];
            if (!groupedByMonth.containsKey(month)) {
              groupedByMonth[month] = [];
            }
            groupedByMonth[month]!.add(stat);
          }

          List<String> months = groupedByMonth.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: months.length,
            itemBuilder: (context, index) {
              String month = months[index];
              List<Map<String, dynamic>> monthStats = groupedByMonth[month]!;
              
              double totalIncome = 0;
              double totalExpense = 0;
              
              for (var stat in monthStats) {
                totalIncome += (stat['total_income'] as num?)?.toDouble() ?? 0.0;
                totalExpense += (stat['total_expense'] as num?)?.toDouble() ?? 0.0;
              }
              
              double balance = totalIncome - totalExpense;

              return Card(
                margin: EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(
                    _formatMonth(month),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    'Income: ${totalIncome.toStringAsFixed(2)} | Expense: ${totalExpense.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    balance >= 0 ? '+${balance.toStringAsFixed(2)}' : balance.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  children: [
                    Divider(),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Summary Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Income',
                                  totalIncome,
                                  Colors.green,
                                  Icons.arrow_downward,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Expense',
                                  totalExpense,
                                  Colors.red,
                                  Icons.arrow_upward,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          // Category Breakdown
                          Text(
                            'By Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...monthStats.map((stat) {
                            String categoryName = stat['category_name'] ?? 'Unknown';
                            double income = (stat['total_income'] as num?)?.toDouble() ?? 0.0;
                            double expense = (stat['total_expense'] as num?)?.toDouble() ?? 0.0;
                            
                            if (income == 0 && expense == 0) return SizedBox.shrink();
                            
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      categoryName,
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (income > 0)
                                    Expanded(
                                      child: Text(
                                        '+${income.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.green),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  if (expense > 0)
                                    Expanded(
                                      child: Text(
                                        '-${expense.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.red),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String month) {
    try {
      // month format: YYYY-MM
      final parts = month.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return month;
    }
  }
}
