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

  /// 🔹 Editar transacción existente
  Future<void> updateTransaction(TransactionModel updatedTx) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == updatedTx.id);
      if (index == -1) return;

      final oldTx = _transactions[index];
      _transactions[index] = updatedTx;
      notifyListeners();

      // Actualizar en Firestore
      final oldCollection = oldTx.isIncome ? 'Ingresos' : 'Egresos';
      final newCollection = updatedTx.isIncome ? 'Ingresos' : 'Egresos';

      // Si cambió de tipo (ingreso <-> egreso), eliminar del anterior y crear en el nuevo
      if (oldCollection != newCollection) {
        await _firestore.collection(oldCollection).doc(updatedTx.id).delete();
        
        final docRef = await _firestore.collection(newCollection).add({
          'description': updatedTx.description,
          'category': updatedTx.category,
          'amount': updatedTx.amount,
          'date': updatedTx.date.toIso8601String(),
          'isIncome': updatedTx.isIncome,
          'id_user': _auth.currentUser?.uid,
        });

        // Actualizar el ID local con el nuevo ID de Firestore
        _transactions[index] = TransactionModel(
          id: docRef.id,
          description: updatedTx.description,
          category: updatedTx.category,
          amount: updatedTx.amount,
          date: updatedTx.date,
          isIncome: updatedTx.isIncome,
        );
      } else {
        // Actualizar en la misma colección
        await _firestore.collection(newCollection).doc(updatedTx.id).update({
          'description': updatedTx.description,
          'category': updatedTx.category,
          'amount': updatedTx.amount,
          'date': updatedTx.date.toIso8601String(),
          'isIncome': updatedTx.isIncome,
        });
      }

      debugPrint('✅ Transacción actualizada correctamente');
    } catch (e) {
      debugPrint('❌ Error al actualizar transacción: $e');
    }
  }

  /// 🔹 Eliminar transacción
  Future<void> deleteTransaction(String id, bool isIncome) async {
    try {
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();

      final collection = isIncome ? 'Ingresos' : 'Egresos';
      await _firestore.collection(collection).doc(id).delete();

      debugPrint('✅ Transacción eliminada correctamente');
    } catch (e) {
      debugPrint('❌ Error al eliminar transacción: $e');
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

  /// 💰 Calcular balance total (todos los tiempos)
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

  /// 🔹 Obtener transacciones de un mes específico
  List<TransactionModel> getTransactionsByMonth(int month, int year) {
    return _transactions
        .where((t) => t.date.month == month && t.date.year == year)
        .toList();
  }

  /// 🔹 Obtener ingresos de un mes
  double getMonthIncome(int month, int year) {
    return getTransactionsByMonth(month, year)
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 🔹 Obtener gastos de un mes
  double getMonthExpense(int month, int year) {
    return getTransactionsByMonth(month, year)
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 🔹 Obtener balance de un mes
  double getMonthBalance(int month, int year) {
    return getMonthIncome(month, year) - getMonthExpense(month, year);
  }

  /// 🔍 Buscar transacciones por texto
  List<TransactionModel> searchTransactions(String query, int month, int year) {
    final monthTransactions = getTransactionsByMonth(month, year);
    if (query.isEmpty) return monthTransactions;

    final lowerQuery = query.toLowerCase();
    return monthTransactions.where((t) {
      return t.description.toLowerCase().contains(lowerQuery) ||
          t.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}