import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
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

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final transactions = provider.transactions;

    final now = DateTime.now();
    final currentMonthTx = transactions.where(
      (tx) => tx.date.month == now.month && tx.date.year == now.year,
    );

    final ingresos = currentMonthTx.where((tx) => tx.isIncome).toList();
    final egresos = currentMonthTx.where((tx) => !tx.isIncome).toList();

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
            onPressed: () => themeProvider.toggleTheme(),
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
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 💰 Balance Total centrado
                            Center(
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                color: Theme.of(context).colorScheme.primary,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'totalBalance'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '\$${NumberFormat("#,##0.00", "es_CO").format(provider.totalBalance)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // 📈 Gráfica de Ingresos (verdes variados)
                            if (ingresos.isNotEmpty)
                              _buildChartCard(
                                context,
                                title: 'income_chart'.tr(),
                                transactions: ingresos,
                                isIncome: true,
                              ),

                            const SizedBox(height: 25),

                            // 📉 Gráfica de Egresos (rojos variados)
                            if (egresos.isNotEmpty)
                              _buildChartCard(
                                context,
                                title: 'expense_chart'.tr(),
                                transactions: egresos,
                                isIncome: false,
                              ),

                            const SizedBox(height: 30),

                            // 🧾 Últimos movimientos
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'lastMovements'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...transactions.take(10).map((tx) => _TransactionTile(tx)),
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

  /// 🔹 Tarjeta con gráfico circular — ahora con colores variados según tipo
  Widget _buildChartCard(BuildContext context,
      {required String title,
      required List<TransactionModel> transactions,
      required bool isIncome}) {
    final Map<String, double> data = {};
    for (var tx in transactions) {
      data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
    }

    // 🎨 Paletas de colores
    final incomeColors = [
      Colors.green[800]!,
      Colors.green[600]!,
      Colors.lightGreen[500]!,
      Colors.teal[400]!,
      Colors.greenAccent[400]!,
    ];

    final expenseColors = [
      Colors.red[800]!,
      Colors.red[600]!,
      Colors.deepOrange[500]!,
      Colors.pink[400]!,
      Colors.redAccent[400]!,
    ];

    final colorPalette = isIncome ? incomeColors : expenseColors;

    final sections = data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      final color = colorPalette[index % colorPalette.length];
      final percentage =
          (entry.value / data.values.reduce((a, b) => a + b) * 100)
              .toStringAsFixed(1);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key}\n$percentage%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 35,
                  sectionsSpace: 2,
                ),
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
            color: tx.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(tx.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(tx.category,
            style: const TextStyle(color: Colors.grey)),
        trailing: Text(
          '\$${NumberFormat("#,##0.00", "es_CO").format(tx.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: tx.isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
