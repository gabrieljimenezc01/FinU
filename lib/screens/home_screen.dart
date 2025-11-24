import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

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

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // 🔹 NUEVA FUNCIÓN: Obtiene el nombre del mes traducido
  String _getMonthName(int month) {
    const monthKeys = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    
    if (month >= 1 && month <= 12) {
      return monthKeys[month - 1].tr();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final transactions = provider.transactions;

    // 🔹 Datos del mes actual
    final now = DateTime.now();
    final currentMonthTx = transactions.where(
      (tx) => tx.date.month == now.month && tx.date.year == now.year,
    ).toList();

    final ingresos = currentMonthTx.where((tx) => tx.isIncome).toList();
    final egresos = currentMonthTx.where((tx) => !tx.isIncome).toList();

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
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: transactions.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'noTransactions'.tr(),
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 18),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/add'),
                                icon: const Icon(Icons.add),
                                label: Text('add'.tr()),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 🔹 Balance total general - Diseño mejorado
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: provider.totalBalance >= 0
                                    ? [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.8),
                                      ]
                                    : [
                                        Colors.red[700]!,
                                        Colors.red[500]!,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.account_balance_wallet,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'totalBalance'.tr(),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'totalAssets'.tr(),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              provider.totalBalance >= 0
                                                  ? Icons.trending_up
                                                  : Icons.trending_down,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              provider.totalBalance >= 0
                                                  ? 'positive'.tr()
                                                  : 'negative'.tr(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '\$${NumberFormat("#,##0.00", "es_CO").format(provider.totalBalance)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 🔹 Resumen del mes actual - Diseño mejorado
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.calendar_month,
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      // 🔹 CAMBIO: Usar la función _getMonthName en lugar de DateFormat
                                      _capitalize(_getMonthName(now.month)),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Ingresos y Egresos en fila
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MonthSummaryItem(
                                        icon: Icons.trending_up,
                                        label: 'income'.tr(),
                                        amount: monthIncome,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _MonthSummaryItem(
                                        icon: Icons.trending_down,
                                        label: 'expense'.tr(),
                                        amount: monthExpense,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Divider decorativo
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.withOpacity(0.1),
                                        Colors.grey.withOpacity(0.3),
                                        Colors.grey.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Balance del mes destacado
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: monthBalance >= 0
                                          ? [
                                              Colors.teal.withOpacity(0.1),
                                              Colors.teal.withOpacity(0.05),
                                            ]
                                          : [
                                              Colors.red.withOpacity(0.1),
                                              Colors.red.withOpacity(0.05),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: monthBalance >= 0
                                          ? Colors.teal.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: monthBalance >= 0
                                                  ? Colors.teal
                                                  : Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.account_balance_wallet,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'monthBalance'.tr(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                monthBalance >= 0
                                                    ? 'surplus'.tr()
                                                    : 'deficit'.tr(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: monthBalance >= 0
                                                      ? Colors.teal
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Flexible(
                                        child: Text(
                                          '\$${NumberFormat("#,##0", "es_CO").format(monthBalance.abs())}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: monthBalance >= 0
                                                ? Colors.teal[700]
                                                : Colors.red[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Gráfico de Ingresos
                        if (ingresos.isNotEmpty)
                          _buildChartCard(
                            context,
                            title: 'incomeByCategory'.tr(),
                            transactions: ingresos,
                            isIncome: true,
                          ),

                        if (ingresos.isNotEmpty && egresos.isNotEmpty)
                          const SizedBox(height: 20),

                        // 🔹 Gráfico de Egresos
                        if (egresos.isNotEmpty)
                          _buildChartCard(
                            context,
                            title: 'expenseByCategory'.tr(),
                            transactions: egresos,
                            isIncome: false,
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
                              onPressed: () => Navigator.pushNamed(
                                  context, '/transactions'),
                              child: Text('seeAll'.tr()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        ...transactions.take(5).map((tx) => _TransactionTile(
                              tx: tx,
                              onTap: () => _showTransactionOptions(context, tx),
                            )),

                        const SizedBox(height: 80), // Espacio para el FAB
                      ],
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

  /// 🔹 Método para construir gráficos circulares separados
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
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,##0", "es_CO");
    return formatter.format(amount);
  }
}

// 🔹 Widget para items del resumen mensual
class _MonthSummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _MonthSummaryItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '\$${NumberFormat("#,##0", "es_CO").format(amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
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
          '${tx.category} • ${DateFormat('dd MMM', context.locale.toString()).format(tx.date)}',
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