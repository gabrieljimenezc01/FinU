import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import '../widgets/expense_chart.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Provider.of<ExpenseProvider>(context, listen: false)
          .fetchTransactionsFromFirebase(user.uid);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final transactions = provider.transactions;
    
    // 🔹 Datos del mes actual
    final now = DateTime.now();
    final monthIncome = provider.getMonthIncome(now.month, now.year);
    final monthExpense = provider.getMonthExpense(now.month, now.year);
    final monthBalance = monthIncome - monthExpense;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'homeTitle'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'themeToggle'.tr(),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'noTransactions'.tr(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/add'),
                            icon: const Icon(Icons.add),
                            label: Text('addFirst'.tr()),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Balance total general
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              color: Theme.of(context).colorScheme.primary,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'totalBalance'.tr(),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '\$${NumberFormat("#,##0.00", "es_CO").format(provider.totalBalance)}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 🔹 Resumen del mes actual
                            Text(
                              'Resumen de ${DateFormat.MMMM('es').format(now)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

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

                            // 🔹 Balance del mes
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          color: monthBalance >= 0
                                              ? Colors.teal
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Balance del mes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: monthBalance >= 0
                                                ? Colors.teal
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '\$${NumberFormat("#,##0.00", "es_CO").format(monthBalance)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: monthBalance >= 0
                                            ? Colors.teal
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 🔹 Gráfico
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ExpenseChart(
                                    transactions: provider.getTransactionsByMonth(
                                        now.month, now.year)),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 🔹 Últimas transacciones
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('lastMovements'.tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/transactions'),
                                  child: Text('seeAll'.tr()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            ...transactions.take(5).map((tx) => _TransactionTile(
                                  tx: tx,
                                  onTap: () => _showTransactionOptions(context, tx),
                                )),
                          ],
                        ),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        icon: const Icon(Icons.add),
        label: Text('add'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break; // Ya estamos en Home
            case 1:
              Navigator.pushNamed(context, '/transactions');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home), label: 'home'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.list_alt), label: 'transactions'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.person), label: 'profile'.tr()),
        ],
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
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: Text('edit'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add', arguments: tx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
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
                SnackBar(content: Text('transactionDeleted'.tr())),
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
          '${tx.category} • ${DateFormat('dd MMM', 'es').format(tx.date)}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          '\$${NumberFormat("#,##0.00", "es_CO").format(tx.amount)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.isIncome ? Colors.green : Colors.red),
        ),
      ),
    );
  }
}