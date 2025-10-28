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
  bool _isIncome = false;
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
        return 'Comida';
      case 'transporte':
        return 'Transporte';
      case 'entretenimiento':
        return 'Entretenimiento';
      case 'hogar':
        return 'Hogar';
      case 'salud':
        return 'Salud';
      case 'compras':
        return 'Compras';
      case 'educacion':
      case 'educación':
        return 'Educación';
      case 'suscripciones':
        return 'Suscripciones';
      case 'finanzas':
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
      print('✅ Modelo IA cargado y listo.');
    } catch (e) {
      print('❌ Error al cargar modelo: $e');
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
      print('⚠️ Error en predicción: $e');
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('add_transaction_title'.tr()), // 🌍 Traducido
      ),
      body: Padding(
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
                keyboardType: TextInputType.number,
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

              const SizedBox(height: 16),

              /// 💵 Tipo de transacción
              SwitchListTile(
                title: Text('is_income'.tr()),
                value: _isIncome,
                activeThumbColor: Colors.teal,
                onChanged: (v) => setState(() => _isIncome = v),
              ),

              const SizedBox(height: 30),

              /// 💾 Botón Guardar
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.teal,
                ),
                label: Text('save'.tr()),
                onPressed: _loadingCategory
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          provider.addTransaction(
                            TransactionModel(
                              id: const Uuid().v4(),
                              description: _descController.text,
                              amount: double.parse(_amountController.text),
                              category: _category,
                              date: DateTime.now(),
                              isIncome: _isIncome,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
