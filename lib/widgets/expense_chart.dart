import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class ExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ExpenseChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenseTransactions =
        transactions.where((tx) => !tx.isIncome).toList();

    final Map<String, double> categoryTotals = {};
    for (var tx in expenseTransactions) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    if (categoryTotals.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay gastos registrados 🧾',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final List<PieChartSectionData> sections = categoryTotals.entries.map((e) {
      final double total = e.value;
      final double percentage =
          total / categoryTotals.values.reduce((a, b) => a + b) * 100;

      return PieChartSectionData(
        color: _getColorForCategory(e.key),
        value: total,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        const Text(
          'Distribución de Gastos por Categoría',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: categoryTotals.entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(e.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key} (\$${NumberFormat("#,##0.00", "es_CO").format(e.value)})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'comida':
        return Colors.orange;
      case 'transporte':
        return Colors.blue;
      case 'entretenimiento':
        return Colors.purple;
      case 'hogar':
        return Colors.green;
      case 'salud':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }
}
