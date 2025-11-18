import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/theme_provider.dart';
import '../providers/expense_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final provider = Provider.of<ExpenseProvider>(context);
    
    // Estadísticas del usuario
    final totalTransactions = provider.transactions.length;
    final totalIncome = provider.transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = provider.transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🔹 Card de Información del Usuario
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: user?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoURL!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nombre
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Email
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email_outlined,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              user?.email ?? 'Sin email',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
          ),

          const SizedBox(height: 24),

          // 🔹 Estadísticas del Usuario
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
                          Icons.bar_chart,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Estadísticas Generales',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Total de Transacciones
                  _StatItem(
                    icon: Icons.receipt_long,
                    label: 'Total de transacciones',
                    value: '$totalTransactions',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  
                  // Total Ingresos
                  _StatItem(
                    icon: Icons.trending_up,
                    label: 'Total ingresos',
                    value: '\$${NumberFormat("#,##0", "es_CO").format(totalIncome)}',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  // Total Gastos
                  _StatItem(
                    icon: Icons.trending_down,
                    label: 'Total gastos',
                    value: '\$${NumberFormat("#,##0", "es_CO").format(totalExpense)}',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🔹 Acciones
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.help_outline,
                  title: 'Ayuda y Soporte',
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente: Centro de ayuda'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.info_outline,
                  title: 'Acerca de',
                  color: Colors.purple,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Acerca de'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('App de Finanzas Personales'),
                            SizedBox(height: 8),
                            Text('Versión: 1.0.0'),
                            SizedBox(height: 8),
                            Text('Desarrollado con ❤️ en Flutter'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  color: Colors.red,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80), // Espacio para el bottom nav
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/transactions');
              break;
            case 2:
              break; // Ya estamos aquí
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Hogar'),
          NavigationDestination(
              icon: Icon(Icons.list_alt), label: 'Transacciones'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// 🔹 Widget para items de estadísticas
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Widget para items de configuración
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// 🔹 Widget para acciones
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
    );
  }
}