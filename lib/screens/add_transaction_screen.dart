import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../services/expense_categorizer.dart'; // 👈 Import del modelo IA

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  final categorizer = ExpenseCategorizer(); // 🧠 Modelo de IA

  String _category = 'Otros'; // Categoría inicial
  bool _isIncome = false;
  bool _loadingCategory = false;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _descController.addListener(_onDescriptionChanged);
  }

  /// 🔤 Normaliza el nombre de la categoría predicha
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

  /// Cargar el modelo IA al iniciar la pantalla
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

  /// Detectar cambios en la descripción y predecir la categoría
  Future<void> _onDescriptionChanged() async {
    final text = _descController.text.trim();

    // No predecir si el modelo no está listo o el texto es muy corto
    if (!_modelReady || text.isEmpty || text.split(' ').length < 2) return;

    setState(() => _loadingCategory = true);
    try {
      final predicted = await categorizer.predictCategory(text);

      // Normalizamos para que coincida con las categorías del Dropdown
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
        title: const Text('Agregar Transacción'),
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
                  labelText: 'Descripción',
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
                    v!.isEmpty ? 'Ingrese una descripción válida' : null,
              ),

              const SizedBox(height: 16),

              /// 💰 Monto
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) => v!.isEmpty ? 'Ingrese un monto' : null,
              ),

              const SizedBox(height: 16),

              /// 🏷️ Categoría (automática + editable)
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoría (IA o manual)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Comida', child: Text('Comida')),
                  DropdownMenuItem(value: 'Transporte', child: Text('Transporte')),
                  DropdownMenuItem(value: 'Entretenimiento', child: Text('Entretenimiento')),
                  DropdownMenuItem(value: 'Hogar', child: Text('Hogar')),
                  DropdownMenuItem(value: 'Salud', child: Text('Salud')),
                  DropdownMenuItem(value: 'Compras', child: Text('Compras')),
                  DropdownMenuItem(value: 'Educación', child: Text('Educación')),
                  DropdownMenuItem(value: 'Suscripciones', child: Text('Suscripciones')),
                  DropdownMenuItem(value: 'Finanzas', child: Text('Finanzas')),
                  DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),

              const SizedBox(height: 16),

              /// 💵 Tipo de transacción
              SwitchListTile(
                title: const Text('¿Es ingreso?'),
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
                label: const Text('Guardar'),
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
