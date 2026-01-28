import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/expense_model.dart';
import '../database/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _filterCategory;
  DateTimeRange? _filterDateRange;
  StreamSubscription<QuerySnapshot>? _expensesSubscription;

  List<Expense> get expenses => _searchQuery.isEmpty &&
          _filterCategory == null &&
          _filterDateRange == null
      ? _expenses
      : _filteredExpenses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  DateTimeRange? get filterDateRange => _filterDateRange;

  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> get expensesByCategory {
    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cancel previous subscription
        _expensesSubscription?.cancel();

        // Listen to Firestore changes
        _expensesSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .orderBy('date', descending: true)
            .snapshots()
            .listen((snapshot) {
          _expenses = snapshot.docs.map((doc) {
            final data = doc.data();
            return Expense(
              id: doc.id,
              title: data['title'],
              amount: data['amount'],
              category: data['category'],
              date: (data['date'] as Timestamp).toDate(),
              description: data['description'],
            );
          }).toList();
          _applyFilters();
          notifyListeners();
        });
      } else {
        // Cancel subscription if no user
        _expensesSubscription?.cancel();
        // Load from local database
        _expenses = await DatabaseHelper.instance.getAllExpenses();
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setFilterDateRange(DateTimeRange? range) {
    _filterDateRange = range;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    _filterDateRange = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredExpenses = _expenses.where((expense) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (expense.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);

      // Category filter
      bool matchesCategory =
          _filterCategory == null || expense.category == _filterCategory;

      // Date range filter
      bool matchesDateRange = _filterDateRange == null ||
          (expense.date.isAfter(
                  _filterDateRange!.start.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(
                  _filterDateRange!.end.add(const Duration(days: 1))));

      return matchesSearch && matchesCategory && matchesDateRange;
    }).toList();
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Add to Firestore - listener will update _expenses automatically
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .add({
          'title': expense.title,
          'amount': expense.amount,
          'category': expense.category,
          'date': expense.date,
          'description': expense.description,
        });
        // Don't manually add to _expenses - listener will handle it
      } else {
        // Add to local database
        final id = await DatabaseHelper.instance.createExpense(expense);
        _expenses.insert(0, expense.copyWith(id: id.toString()));
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update in Firestore - listener will update _expenses automatically
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .doc(expense.id)
            .update({
          'title': expense.title,
          'amount': expense.amount,
          'category': expense.category,
          'date': expense.date,
          'description': expense.description,
        });
        // Don't manually update _expenses - listener will handle it
      } else {
        // Update in local database
        await DatabaseHelper.instance.updateExpense(expense);
        final index = _expenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _expenses[index] = expense;
          _applyFilters();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete from Firestore - listener will update _expenses automatically
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .doc(id)
            .delete();
        // Don't manually remove from _expenses - listener will handle it
      } else {
        // Delete from local database
        await DatabaseHelper.instance.deleteExpense(int.parse(id));
        _expenses.removeWhere((expense) => expense.id == id);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  List<Expense> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return _expenses.where((expense) {
      return expense.date
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Future<String?> uploadImage(String imagePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/expenses/$fileName');

      await ref.putFile(File(imagePath));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void dispose() {
    _expensesSubscription?.cancel();
  }
}
