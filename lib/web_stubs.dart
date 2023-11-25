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
  dynamic elementAt(int index) {
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
  dynamic firstWhere(bool Function(dynamic element) test,
      {Function()? orElse}) {
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
  dynamic get last => throw UnimplementedError();

  @override
  dynamic lastWhere(bool Function(dynamic element) test, {Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> map<T>(T Function(dynamic e) toElement) {
    throw UnimplementedError();
  }

  @override
  dynamic reduce(Function(dynamic value, dynamic element) combine) {
    throw UnimplementedError();
  }

  @override
  dynamic get single => throw UnimplementedError();

  @override
  dynamic singleWhere(bool Function(dynamic element) test,
      {Function()? orElse}) {
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

  @override
  dynamic get first => throw UnimplementedError();

  @override
  int get length => throw UnimplementedError();
}

typedef ScalarFunction = Object? Function(List<Object?> arguments);

class AllowedArgumentCount {
  AllowedArgumentCount(int arg);
}

class Row implements Map<String, dynamic> {
  dynamic columnAt(index) {
    return null;
  }

  @override
  dynamic operator [](Object? key) {
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
  dynamic putIfAbsent(String key, Function() ifAbsent) {
    throw UnimplementedError();
  }

  @override
  dynamic remove(Object? key) {
    throw UnimplementedError();
  }

  @override
  void removeWhere(bool Function(String key, dynamic value) test) {}

  @override
  dynamic update(String key, Function(dynamic value) update,
      {Function()? ifAbsent}) {
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
