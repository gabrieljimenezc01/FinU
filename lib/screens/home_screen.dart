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
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final transactions = provider.transactions;

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
                      child: Text(
                        'noTransactions'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 30),
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child:
                                  ExpenseChart(transactions: transactions),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text('lastMovements'.tr(),
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          ...transactions.reversed
                              .map((tx) => _TransactionTile(tx)),
                        ],
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
          if (index == 1) Navigator.pushNamed(context, '/summary');
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home), label: 'homeTitle'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.bar_chart), label: 'summary'.tr()),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const _TransactionTile(this.tx);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor:
              tx.isIncome ? Colors.green[100] : Colors.red[100],
          child: Icon(
              tx.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: tx.isIncome ? Colors.green : Colors.red),
        ),
        title: Text(tx.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(tx.category,
            style: const TextStyle(color: Colors.grey)),
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
