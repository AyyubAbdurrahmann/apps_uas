import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
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
  bool _isFirebaseInitialized = false;

  List<Expense> get expenses => _searchQuery.isEmpty &&
          _filterCategory == null &&
          _filterDateRange == null
      ? _expenses
      : _filteredExpenses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  DateTimeRange? get filterDateRange => _filterDateRange;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

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

  /// Initialize Firebase dan load expenses
  /// Bisa dipanggil dari SplashScreen atau HomeScreen
  Future<void> initializeAndLoad() async {
    // Check if Firebase sudah ter-initialize
    if (Firebase.apps.isNotEmpty) {
      _isFirebaseInitialized = true;
    }

    await loadExpenses();
  }

  /// Load expenses dari Firebase atau local database
  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cek apakah Firebase sudah initialized
      if (Firebase.apps.isEmpty) {
        // Firebase tidak tersedia - gunakan local database
        debugPrint('Firebase not initialized, loading from local database');
        _isFirebaseInitialized = false;
        _expenses = await DatabaseHelper.instance.getAllExpenses();
        _applyFilters();
      } else {
        // Firebase tersedia
        _isFirebaseInitialized = true;
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // User sudah login - listen ke Firestore
          _expensesSubscription?.cancel();

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
          }, onError: (error) {
            debugPrint('Firestore error: $error');
            // Jika ada error Firestore, fallback ke local database
            _fallbackToLocalDatabase();
          });
        } else {
          // User belum login - gunakan local database
          _expensesSubscription?.cancel();
          _expenses = await DatabaseHelper.instance.getAllExpenses();
          _applyFilters();
        }
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      // Fallback ke local database jika ada error apapun
      _fallbackToLocalDatabase();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fallback ke local database jika Firebase error
  Future<void> _fallbackToLocalDatabase() async {
    try {
      _isFirebaseInitialized = false;
      _expenses = await DatabaseHelper.instance.getAllExpenses();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from local database: $e');
      _expenses = [];
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
      if (_isFirebaseInitialized && Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Add to Firestore
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
          return;
        }
      }

      // Add to local database
      final id = await DatabaseHelper.instance.createExpense(expense);
      _expenses.insert(0, expense.copyWith(id: id.toString()));
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      if (_isFirebaseInitialized && Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Update di Firestore
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
          return;
        }
      }

      // Update di local database
      await DatabaseHelper.instance.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      if (_isFirebaseInitialized && Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Delete dari Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('expenses')
              .doc(id)
              .delete();
          return;
        }
      }

      // Delete dari local database
      await DatabaseHelper.instance.deleteExpense(int.parse(id));
      _expenses.removeWhere((expense) => expense.id == id);
      _applyFilters();
      notifyListeners();
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
      if (!_isFirebaseInitialized || Firebase.apps.isEmpty) {
        return null;
      }

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

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    super.dispose();
  }
}
