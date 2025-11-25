import 'dart:async';
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
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  final categorizer = ExpenseCategorizer();
  
  bool isIncome = true; // Por defecto: Ingreso
  String selectedCategory = 'Otros';
  DateTime selectedDate = DateTime.now();
  
  bool _modelReady = false;
  bool _predicting = false;
  Timer? _debounce;
  
  TransactionModel? transactionToEdit;
  bool isEditMode = false;

  // Categorías
  final List<String> incomeCategories = [
    'salary'.tr(),
    'freelance'.tr(),
    'investments'.tr(),
    'sale'.tr(),
    'gift'.tr(),
    'others'.tr(),
  ];

  final List<String> expenseCategories = [
    'food'.tr(),
    'transport'.tr(),
    'entertainment'.tr(),
    'shopping'.tr(),
    'services'.tr(),
    'health'.tr(),
    'education'.tr(),
    'home'.tr(),
    'subscriptions'.tr(),
    'others'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _descriptionController.addListener(_onTextChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is TransactionModel) {
        setState(() {
          transactionToEdit = args;
          isEditMode = true;
          isIncome = args.isIncome;
          _descriptionController.text = args.description;
          _amountController.text = args.amount.toString();
          selectedCategory = args.category;
          selectedDate = args.date;
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onTextChanged);
    _debounce?.cancel();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    try {
      await categorizer.loadModel();
      if (mounted) setState(() => _modelReady = true);
      debugPrint("✅ Modelo IA listo.");
    } catch (e) {
      debugPrint("❌ Error iniciando IA: $e");
    }
  }

  void _onTextChanged() {
    // Solo predecir para GASTOS, no para ingresos
    if (!_modelReady || isIncome) {
      debugPrint("⏸️ No se predice: modelReady=$_modelReady, isIncome=$isIncome");
      return;
    }

    final text = _descriptionController.text.trim();
    debugPrint("📝 Texto cambió: '$text'");

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      debugPrint("⏰ Timer ejecutado, llamando a _predictCategory()");
      _predictCategory();
    });
  }

  String _normalizeCategory(String raw) {
    final lower = raw.toLowerCase().trim();
    debugPrint("🔄 Normalizando: '$raw' -> '$lower'");
    
    // Si ya viene en el formato correcto (español)
    if (['comida', 'transporte', 'entretenimiento', 'compras', 'servicios', 
         'salud', 'educación', 'educacion', 'hogar', 'suscripciones'].contains(lower)) {
      // Capitalizar primera letra
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
    
    // Mapeo de inglés a español (por si acaso)
    switch (lower) {
      case 'food':
        return 'Comida';
      case 'transport':
        return 'Transporte';
      case 'entertainment':
        return 'Entretenimiento';
      case 'home':
        return 'Hogar';
      case 'health':
        return 'Salud';
      case 'shopping':
        return 'Compras';
      case 'education':
        return 'Educación';
      case 'subscriptions':
        return 'Suscripciones';
      case 'services':
        return 'Servicios';
      default:
        debugPrint("⚠️ Categoría no reconocida: '$raw' -> 'Otros'");
        return 'Otro';
    }
  }

  Future<void> _predictCategory() async {
    if (!_modelReady || _predicting || isIncome) {
      debugPrint("⏸️ Predicción cancelada: modelReady=$_modelReady, predicting=$_predicting, isIncome=$isIncome");
      return;
    }

    final text = _descriptionController.text.trim();
    debugPrint("🔍 Intentando predecir para: '$text'");
    
    if (text.isEmpty || text.split(' ').length < 2) {
      debugPrint("⚠️ Texto muy corto o vacío, mínimo 2 palabras");
      return;
    }

    if (mounted) setState(() => _predicting = true);

    try {
      debugPrint("🤖 Llamando a la IA...");
      final predicted = await categorizer.predictCategory(text);
      debugPrint("✅ IA retornó: '$predicted'");
      
      final normalized = _normalizeCategory(predicted);
      debugPrint("🔄 Normalizado a: '$normalized'");

      if (mounted && !isIncome) {
        setState(() {
          selectedCategory = normalized;
          debugPrint("✨ Categoría actualizada en UI: '$selectedCategory'");
        });
      }
    } catch (e) {
      debugPrint("❌ Error IA: $e");
    } finally {
      if (mounted) {
        setState(() => _predicting = false);
      }
    }
  }

  List<String> get currentCategories =>
      isIncome ? incomeCategories : expenseCategories;

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('enter_valid_amount'.tr())),
        );
        return;
      }
      
      final transaction = TransactionModel(
        id: isEditMode ? transactionToEdit!.id : const Uuid().v4(),
        description: _descriptionController.text.trim(),
        category: selectedCategory,
        amount: amount,
        date: selectedDate,
        isIncome: isIncome,
      );

      if (isEditMode) {
        provider.updateTransaction(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('transaction_updated'.tr())),
        );
      } else {
        provider.addTransaction(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('transaction_saved'.tr())),
        );
      }

      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditMode ? 'edit_transaction'.tr() : 'add_transaction'.tr()),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 🔹 Selector de tipo: Ingreso / Gasto (Diseño mejorado)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                height: 90,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          debugPrint("🔄 Cambiando a Ingreso");
                          setState(() {
                            isIncome = true;
                            if (!incomeCategories.contains(selectedCategory)) {
                              selectedCategory = 'Otros';
                            }
                            _debounce?.cancel();
                            if (_predicting) {
                              _predicting = false;
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isIncome
                                ? LinearGradient(
                                    colors: [
                                      Colors.green[600]!,
                                      Colors.green[400]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isIncome
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.arrow_upward,
                                  color:
                                      isIncome ? Colors.white : Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'income'.tr(),
                                style: TextStyle(
                                  color: isIncome ? Colors.white : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          debugPrint("🔄 Cambiando a Gasto");
                          setState(() {
                            isIncome = false;
                            if (!expenseCategories
                                .contains(selectedCategory)) {
                              selectedCategory = 'Otros';
                            }
                          });
                          if (_descriptionController.text.trim().isNotEmpty) {
                            debugPrint(
                                "🚀 Forzando predicción al cambiar a Gasto");
                            Future.delayed(
                                const Duration(milliseconds: 100), () {
                              _predictCategory();
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: !isIncome
                                ? LinearGradient(
                                    colors: [
                                      Colors.red[600]!,
                                      Colors.red[400]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: !isIncome
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: !isIncome ? Colors.white : Colors.red,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'expense'.tr(),
                                style: TextStyle(
                                  color: !isIncome ? Colors.white : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Descripción
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.description_outlined,
                        color: Colors.grey[600]),
                    suffixIcon: _predicting && !isIncome
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (!isIncome && _modelReady
                            ? Icon(Icons.auto_fix_high,
                                color: Colors.teal[400])
                            : null),
                    labelText: 'description_label'.tr(),
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'enter_description'.tr();
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Monto
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.attach_money, color: Colors.grey[600]),
                    labelText: 'amount_label'.tr(),
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'enter_amount'.tr();
                    }
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'enter_valid_number'.tr();
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Categoría
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isIncome ? Colors.green : Colors.red)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        color: isIncome ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentCategories.contains(selectedCategory)
                              ? selectedCategory
                              : null,
                          isExpanded: true,
                          hint: Text(
                            isIncome
                                ? 'category_manual'.tr() : 'category_ai_manual'.tr(),
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          items: currentCategories
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedCategory = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Fecha
            GestureDetector(
              onTap: _selectDate,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                          Icons.calendar_today_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'date_label'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM yyyy', context.locale.languageCode)
                                  .format(selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 🔹 Botón Guardar (Diseño mejorado)
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [Colors.green[600]!, Colors.green[400]!]
                      : [Colors.red[600]!, Colors.red[400]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isIncome ? Colors.green : Colors.red)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isEditMode ? 'update'.tr() : 'save'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Botón Eliminar (solo en modo edición)
            if (isEditMode) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text('delete_transaction_title'.tr()),
                      content: Text('delete_transaction_confirm'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<ExpenseProvider>(context,
                                    listen: false)
                                .deleteTransaction(
                                    transactionToEdit!.id, isIncome);
                            Navigator.pop(context);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                  content: Text('transaction_deleted'.tr())),
                            );
                          },
                          child: Text('delete'.tr(),
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text(
                      'delete_transaction'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}