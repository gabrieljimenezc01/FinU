import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../widgets/expense_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final transactions = provider.transactions;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Mis Gastos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      drawer: const CustomDrawer(), // ✅ Se añadió el menú lateral

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: transactions.isEmpty
            ? const Center(
                child: Text(
                  'Aún no hay transacciones',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 💰 Balance general
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
                            const Text(
                              'Saldo total',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${NumberFormat("#,##0.00", "es_CO").format(provider.totalBalance)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 📊 Gráfico de gastos por categoría
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ExpenseChart(transactions: transactions),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🧾 Últimos movimientos
                    Text(
                      'Últimos movimientos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ...transactions.reversed.map((tx) => _TransactionTile(tx)),
                  ],
                ),
              ),
      ),

      // ➕ Botón para agregar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),

      // 🔽 Navegación inferior
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.pushNamed(context, '/summary');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Resumen'),
        ],
      ),
    );
  }
}

// 💸 Widget de transacción individual
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
          backgroundColor: tx.isIncome ? Colors.green[100] : Colors.red[100],
          child: Icon(
            tx.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: tx.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          tx.category,
          style: const TextStyle(color: Colors.grey),
        ),
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
