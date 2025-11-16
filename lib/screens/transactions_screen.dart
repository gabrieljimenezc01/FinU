import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../providers/expense_provider.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    // 🔹 Obtener datos del mes seleccionado
    final monthIncome = provider.getMonthIncome(selectedMonth, selectedYear);
    final monthExpense = provider.getMonthExpense(selectedMonth, selectedYear);
    final monthBalance = monthIncome - monthExpense;

    // 🔹 Filtrar transacciones por búsqueda
    final filteredTransactions = provider.searchTransactions(
      searchQuery,
      selectedMonth,
      selectedYear,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('transactions'.tr()),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔹 Selector de mes y año
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: selectedMonth,
                  underline: const SizedBox(),
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              DateFormat.MMMM('es')
                                  .format(DateTime(0, m))
                                  .capitalize(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedMonth = val ?? selectedMonth),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: selectedYear,
                  underline: const SizedBox(),
                  items: [2023, 2024, 2025, 2026]
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedYear = val ?? selectedYear),
                ),
              ],
            ),
          ),

          // 🔹 Cards de resumen del mes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'income'.tr(),
                        amount: monthIncome,
                        color: Colors.green,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'expense'.tr(),
                        amount: monthExpense,
                        color: Colors.red,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  color: monthBalance >= 0
                      ? Colors.teal.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: monthBalance >= 0 ? Colors.teal : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'total_balance'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: monthBalance >= 0 ? Colors.teal : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${NumberFormat("#,##0.00", "es_CO").format(monthBalance)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: monthBalance >= 0 ? Colors.teal : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'searchTransactions'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Lista de transacciones
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'noTransactionsMonth'.tr()
                              : 'noResultsFound'.tr(),
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      return _TransactionTile(
                        tx: tx,
                        onTap: () => _showTransactionOptions(context, tx),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: Text('edit'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add', arguments: tx);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: Text('delete'.tr()),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, tx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('deleteTransaction'.tr()),
        content: Text('confirmDelete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ExpenseProvider>(context, listen: false)
                  .deleteTransaction(tx.id, tx.isIncome);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('transactionDeleted'.tr()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
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
    return Card(
      color: color.withOpacity(0.15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '\$${NumberFormat("#,##0.00", "es_CO").format(amount)}',
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;

  const _TransactionTile({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: tx.isIncome ? Colors.green[100] : Colors.red[100],
          child: Icon(tx.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: tx.isIncome ? Colors.green : Colors.red),
        ),
        title: Text(tx.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${tx.category} • ${DateFormat('dd MMM yyyy', 'es').format(tx.date)}',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: Text(
          '\$${NumberFormat("#,##0.00", "es_CO").format(tx.amount)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: tx.isIncome ? Colors.green : Colors.red),
        ),
      ),
    );
  }
}

// 🔹 Extensión para capitalizar
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}