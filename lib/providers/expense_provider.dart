import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class ExpenseProvider with ChangeNotifier {
  final List<TransactionModel> _transactions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TransactionModel> get transactions => _transactions;

  /// 🔹 Agregar transacción local + guardar en Firestore
  Future<void> addTransaction(TransactionModel tx) async {
    _transactions.add(tx);
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final collection = tx.isIncome ? 'Ingresos' : 'Egresos';

      await _firestore.collection(collection).add({
        'description': tx.description,
        'category': tx.category,
        'amount': tx.amount,
        'date': tx.date.toIso8601String(),
        'isIncome': tx.isIncome,
        'id_user': user.uid,
      });

      debugPrint('✅ Transacción guardada en Firestore ($collection)');
    } catch (e) {
      debugPrint('❌ Error al guardar en Firestore: $e');
    }
  }

  /// 🔹 Cargar transacciones desde Firestore (por usuario)
  Future<void> fetchTransactionsFromFirebase(String userId) async {
    try {
      _transactions.clear();

      // 🔸 Consultar ingresos
      final ingresosSnap = await _firestore
          .collection('Ingresos')
          .where('id_user', isEqualTo: userId)
          .get();

      for (var doc in ingresosSnap.docs) {
        final data = doc.data();
        _transactions.add(
          TransactionModel(
            id: doc.id,
            description: data['description'] ?? '',
            category: data['category'] ?? '',
            amount: (data['amount'] ?? 0).toDouble(),
            date: DateTime.parse(data['date']),
            isIncome: true,
          ),
        );
      }

      // 🔸 Consultar egresos
      final egresosSnap = await _firestore
          .collection('Egresos')
          .where('id_user', isEqualTo: userId)
          .get();

      for (var doc in egresosSnap.docs) {
        final data = doc.data();
        _transactions.add(
          TransactionModel(
            id: doc.id,
            description: data['description'] ?? '',
            category: data['category'] ?? '',
            amount: (data['amount'] ?? 0).toDouble(),
            date: DateTime.parse(data['date']),
            isIncome: false,
          ),
        );
      }

      // 🔸 Ordenar por fecha (más reciente primero)
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
      debugPrint('✅ Transacciones cargadas correctamente');
    } catch (e) {
      debugPrint('❌ Error al cargar transacciones: $e');
    }
  }

  /// 💰 Calcular balance total
  double get totalBalance {
    double income = 0;
    double expense = 0;
    for (var tx in _transactions) {
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return income - expense;
  }
}
