import 'package:flutter/material.dart';
import '../models/transaction.dart';

class ExpenseProvider with ChangeNotifier {
  final List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => _transactions;

  void addTransaction(TransactionModel tx) {
    _transactions.add(tx);
    notifyListeners();
  }

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
