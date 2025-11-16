import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final transactions = provider.transactions;

    // 🔹 Filtrar por mes y año seleccionados
    final filtered = transactions.where((t) =>
        t.date.month == selectedMonth && t.date.year == selectedYear).toList();

    final totalIncome = filtered
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = filtered
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalBalance = totalIncome - totalExpense;

    // 🔹 Lista de transacciones del mes (máximo 5 últimas)
    final recentTransactions = List<TransactionModel>.from(filtered)
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastFive = recentTransactions.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('summary_title'.tr()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Selector de mes y año
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              DateFormat.MMMM('es')
                                  .format(DateTime(0, m))
                                  .capitalize(),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedMonth = val ?? selectedMonth),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: selectedYear,
                  items: [2023, 2024, 2025, 2026]
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedYear = val ?? selectedYear),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Tarjetas de resumen
            Row(
              children: [
                _SummaryCard(
                  title: 'income'.tr(),
                  amount: totalIncome,
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  title: 'expense'.tr(),
                  amount: totalExpense,
                  color: Colors.red,
                  icon: Icons.arrow_downward,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Balance total
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'total_balance'.tr(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${NumberFormat("#,##0.00", "es_CO").format(totalBalance)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color:
                            totalBalance >= 0 ? Colors.teal : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Últimas transacciones
            Expanded(
              child: lastFive.isEmpty
                  ? Center(
                      child: Text('noTransactions'.tr(),
                          style: const TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Últimas transacciones del mes',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: lastFive.length,
                            itemBuilder: (context, index) {
                              final tx = lastFive[index];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: tx.isIncome
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    child: Icon(
                                      tx.isIncome
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color: tx.isIncome
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(tx.description,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    DateFormat('dd MMM yyyy', 'es')
                                        .format(tx.date),
                                  ),
                                  trailing: Text(
                                    '\$${NumberFormat("#,##0.00", "es_CO").format(tx.amount)}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: tx.isIncome
                                            ? Colors.green
                                            : Colors.red),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),

            // 🔹 Botón volver
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: Text('back'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.15),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '\$${NumberFormat("#,##0.00", "es_CO").format(amount)}',
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Extensión para capitalizar nombres de meses
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
