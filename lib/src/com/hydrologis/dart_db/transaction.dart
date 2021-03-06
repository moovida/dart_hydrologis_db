part of dart_hydrologis_db;

/// Helper class to run transactions.
class Transaction {
  static final String BEGIN = "BEGIN;";
  static final String END = "END;";
  static final String ROLLBACK = "ROLLBACK;";

  final ADb _db;
  bool _transactionOpen = false;

  Transaction(this._db);

  /// Opens a transaction.
  void openTransaction() {
    _db.execute(BEGIN);
    _transactionOpen = true;
  }

  /// Closes a transaction.
  void closeTransaction() {
    if (_transactionOpen) {
      _db.execute(END);
    }
    _transactionOpen = false;
  }

  /// Rollback changes.
  void rollback() {
    if (_transactionOpen) {
      _db.execute(ROLLBACK);
    }
    _transactionOpen = false;
  }

  /// Run a function inside a transaction.
  ///
  /// If the transaction is not open, the method also opens it.
  /// In case of exception a rollback is performed.
  /// If the function finishes properly, the transaction is closed.
  dynamic runInTransaction(Function function) {
    if (!_transactionOpen) {
      openTransaction();
    }
    try {
      dynamic result = function(_db);
      closeTransaction();
      return result;
    } on Exception catch (e, s) {
      SLogger().e("Error during transaction.", e, s);
      rollback();
    }
    return null;
  }
}

class TransactionAsync {
  static final String BEGIN = "BEGIN;";
  static final String END = "END;";
  static final String ROLLBACK = "ROLLBACK;";

  final ADbAsync _db;
  bool _transactionOpen = false;

  TransactionAsync(this._db);

  /// Opens a transaction.
  Future<void> openTransaction() async {
    await _db.execute(BEGIN);
    _transactionOpen = true;
  }

  /// Closes a transaction.
  Future<void> closeTransaction() async {
    if (_transactionOpen) {
      await _db.execute(END);
    }
    _transactionOpen = false;
  }

  /// Rollback changes.
  Future<void> rollback() async {
    if (_transactionOpen) {
      await _db.execute(ROLLBACK);
    }
    _transactionOpen = false;
  }

  /// Run a function inside a transaction.
  ///
  /// If the transaction is not open, the method also opens it.
  /// In case of exception a rollback is performed.
  /// If the function finishes properly, the transaction is closed.
  Future<dynamic> runInTransaction(Function function) async {
    if (!_transactionOpen) {
      await openTransaction();
    }
    try {
      dynamic result = await function(_db);
      await closeTransaction();
      return result;
    } on Exception catch (e, s) {
      SLogger().e("Error during transaction.", e, s);
      await rollback();
    }
    return null;
  }
}
