import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../services/expense_categorizer.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  final categorizer = ExpenseCategorizer();

  String _category = 'Otros';
  bool _loadingCategory = false;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _descController.addListener(_onDescriptionChanged);
  }

  String _normalizeCategory(String raw) {
    final lower = raw.toLowerCase().trim();
    switch (lower) {
      case 'comida':
      case 'food':
        return 'Comida';
      case 'transporte':
      case 'transport':
        return 'Transporte';
      case 'entretenimiento':
      case 'entertainment':
        return 'Entretenimiento';
      case 'hogar':
      case 'home':
        return 'Hogar';
      case 'salud':
      case 'health':
        return 'Salud';
      case 'compras':
      case 'shopping':
        return 'Compras';
      case 'educacion':
      case 'educación':
      case 'education':
        return 'Educación';
      case 'suscripciones':
      case 'subscriptions':
        return 'Suscripciones';
      case 'finanzas':
      case 'finance':
        return 'Finanzas';
      default:
        return 'Otros';
    }
  }

  Future<void> _initializeModel() async {
    try {
      setState(() => _loadingCategory = true);
      await categorizer.loadModel();
      setState(() {
        _modelReady = true;
        _loadingCategory = false;
      });
      debugPrint('✅ Modelo IA cargado y listo.');
    } catch (e) {
      debugPrint('❌ Error al cargar modelo: $e');
      setState(() => _loadingCategory = false);
    }
  }

  Future<void> _onDescriptionChanged() async {
    final text = _descController.text.trim();
    if (!_modelReady || text.isEmpty || text.split(' ').length < 2) return;

    setState(() => _loadingCategory = true);
    try {
      final predicted = await categorizer.predictCategory(text);
      final normalized = _normalizeCategory(predicted);
      setState(() => _category = normalized);
    } catch (e) {
      debugPrint('⚠️ Error en predicción: $e');
    } finally {
      setState(() => _loadingCategory = false);
    }
  }

  @override
  void dispose() {
    categorizer.close();
    _descController.removeListener(_onDescriptionChanged);
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context, bool isIncome) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    if (_loadingCategory) return; // evitar doble envío
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null) {
      // Validación extra por si el número no es correcto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enter_amount'.tr())),
      );
      return;
    }

    final tx = TransactionModel(
      id: const Uuid().v4(),
      description: _descController.text.trim(),
      amount: amount,
      category: _category,
      date: DateTime.now(),
      isIncome: isIncome,
    );

    try {
      await provider.addTransaction(tx);
      Navigator.pop(context); // cerrar pantalla al guardar
    } catch (e) {
      debugPrint('Error guardando transacción: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_saving'.tr(args: ['']))), // puedes agregar clave en JSON
      );
    }
  }

  // Reutilizamos el form widget para cada pestaña (ingreso/egreso)
  Widget _buildForm(BuildContext context, bool isIncome) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 10),

            /// 📝 Descripción
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'description'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note_alt_outlined),
                suffixIcon: _loadingCategory
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_outlined, color: Colors.teal),
              ),
              validator: (v) =>
                  v!.isEmpty ? 'enter_valid_description'.tr() : null,
            ),

            const SizedBox(height: 16),

            /// 💰 Monto
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'amount'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              validator: (v) => v!.isEmpty ? 'enter_amount'.tr() : null,
            ),

            const SizedBox(height: 16),

            /// 🏷️ Categoría (IA o manual)
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'category_ai_or_manual'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'Comida', child: Text('food'.tr())),
                DropdownMenuItem(value: 'Transporte', child: Text('transport'.tr())),
                DropdownMenuItem(value: 'Entretenimiento', child: Text('entertainment'.tr())),
                DropdownMenuItem(value: 'Hogar', child: Text('home'.tr())),
                DropdownMenuItem(value: 'Salud', child: Text('health'.tr())),
                DropdownMenuItem(value: 'Compras', child: Text('shopping'.tr())),
                DropdownMenuItem(value: 'Educación', child: Text('education'.tr())),
                DropdownMenuItem(value: 'Suscripciones', child: Text('subscriptions'.tr())),
                DropdownMenuItem(value: 'Finanzas', child: Text('finance'.tr())),
                DropdownMenuItem(value: 'Otros', child: Text('others'.tr())),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),

            const SizedBox(height: 30),

            /// 💾 Botón Guardar (usa isIncome segun la pestaña)
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: isIncome ? Colors.green : Colors.red,
              ),
              label: Text('save'.tr()),
              onPressed: _loadingCategory
                  ? null
                  : () async {
                      await _submit(context, isIncome);
                    },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos DefaultTabController para las dos pestañas
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('add_transaction_title'.tr()),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.arrow_upward),
                text: 'income'.tr(),
              ),
              Tab(
                icon: const Icon(Icons.arrow_downward),
                text: 'expense'.tr(),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 0: Ingreso
            _buildForm(context, true),
            // Tab 1: Gasto
            _buildForm(context, false),
          ],
        ),
      ),
    );
  }
}
