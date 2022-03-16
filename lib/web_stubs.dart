class Database {
  late int lastInsertRowId;
  void dispose() {}
  dynamic prepare(sql) => null;
  void execute(args) {}
  dynamic getUpdatedRows() => null;
  void createFunction({
    String? functionName,
    ScalarFunction? function,
    AllowedArgumentCount? argumentCount,
    bool deterministic = false,
    bool directOnly = true,
  }) {}
}

class PreparedStatement {
  void execute(args) {}
  void dispose() {}
  dynamic select(args) {}
}

class ResultSet implements Iterable<dynamic> {
  late int length;
  late dynamic first;

  @override
  bool any(bool Function(dynamic element) test) {
    throw UnimplementedError();
  }

  @override
  Iterable<R> cast<R>() {
    throw UnimplementedError();
  }

  @override
  bool contains(Object? element) {
    throw UnimplementedError();
  }

  @override
  elementAt(int index) {
    throw UnimplementedError();
  }

  @override
  bool every(bool Function(dynamic element) test) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(dynamic element) toElements) {
    throw UnimplementedError();
  }

  @override
  firstWhere(bool Function(dynamic element) test, {Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  T fold<T>(
      T initialValue, T Function(T previousValue, dynamic element) combine) {
    throw UnimplementedError();
  }

  @override
  Iterable followedBy(Iterable other) {
    throw UnimplementedError();
  }

  @override
  void forEach(void Function(dynamic element) action) {}

  @override
  bool get isEmpty => throw UnimplementedError();

  @override
  bool get isNotEmpty => throw UnimplementedError();

  @override
  Iterator get iterator => throw UnimplementedError();

  @override
  String join([String separator = ""]) {
    throw UnimplementedError();
  }

  @override
  get last => throw UnimplementedError();

  @override
  lastWhere(bool Function(dynamic element) test, {Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> map<T>(T Function(dynamic e) toElement) {
    throw UnimplementedError();
  }

  @override
  reduce(Function(dynamic value, dynamic element) combine) {
    throw UnimplementedError();
  }

  @override
  get single => throw UnimplementedError();

  @override
  singleWhere(bool Function(dynamic element) test, {Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Iterable skip(int count) {
    throw UnimplementedError();
  }

  @override
  Iterable skipWhile(bool Function(dynamic value) test) {
    throw UnimplementedError();
  }

  @override
  Iterable take(int count) {
    throw UnimplementedError();
  }

  @override
  Iterable takeWhile(bool Function(dynamic value) test) {
    throw UnimplementedError();
  }

  @override
  List toList({bool growable = true}) {
    throw UnimplementedError();
  }

  @override
  Set toSet() {
    throw UnimplementedError();
  }

  @override
  Iterable where(bool Function(dynamic element) test) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> whereType<T>() {
    throw UnimplementedError();
  }
}

class ScalarFunction {}

class AllowedArgumentCount {
  AllowedArgumentCount(int arg);
}

class Row implements Map<String, dynamic> {
  dynamic columnAt(index) {
    return null;
  }

  @override
  operator [](Object? key) {
    throw UnimplementedError();
  }

  @override
  void operator []=(String key, value) {}

  @override
  void addAll(Map<String, dynamic> other) {}

  @override
  void addEntries(Iterable<MapEntry<String, dynamic>> newEntries) {}

  @override
  Map<RK, RV> cast<RK, RV>() {
    throw UnimplementedError();
  }

  @override
  void clear() {}

  @override
  bool containsKey(Object? key) {
    throw UnimplementedError();
  }

  @override
  bool containsValue(Object? value) {
    throw UnimplementedError();
  }

  @override
  Iterable<MapEntry<String, dynamic>> get entries => throw UnimplementedError();

  @override
  void forEach(void Function(String key, dynamic value) action) {}

  @override
  bool get isEmpty => throw UnimplementedError();

  @override
  bool get isNotEmpty => throw UnimplementedError();

  @override
  Iterable<String> get keys => throw UnimplementedError();

  @override
  int get length => throw UnimplementedError();

  @override
  Map<K2, V2> map<K2, V2>(
      MapEntry<K2, V2> Function(String key, dynamic value) convert) {
    throw UnimplementedError();
  }

  @override
  putIfAbsent(String key, Function() ifAbsent) {
    throw UnimplementedError();
  }

  @override
  remove(Object? key) {
    throw UnimplementedError();
  }

  @override
  void removeWhere(bool Function(String key, dynamic value) test) {}

  @override
  update(String key, Function(dynamic value) update, {Function()? ifAbsent}) {
    throw UnimplementedError();
  }

  @override
  void updateAll(Function(String key, dynamic value) update) {}

  @override
  Iterable get values => throw UnimplementedError();
}

dynamic get sqlite3 {
  return null;
}
