import 'dart:async';
import 'package:flutter/foundation.dart';

/// Сервис для управления автоматической синхронизацией данных
class SyncService extends ChangeNotifier {
  // Интервалы синхронизации для разных типов данных (в секундах)
  static const int _tasksSyncInterval = 5;
  static const int _shoppingSyncInterval = 5;
  static const int _cleaningSyncInterval = 10;
  static const int _roomMembersSyncInterval = 30;

  // Таймеры для каждого типа данных
  Timer? _tasksTimer;
  Timer? _shoppingTimer;
  Timer? _cleaningTimer;
  Timer? _roomMembersTimer;

  // Флаги для отслеживания активности
  bool _isTasksSyncing = false;
  bool _isShoppingSyncing = false;
  bool _isCleaningSyncing = false;
  bool _isRoomMembersSyncing = false;

  // Последние времена синхронизации
  DateTime? _lastTasksSync;
  DateTime? _lastShoppingSync;
  DateTime? _lastCleaningSync;
  DateTime? _lastRoomMembersSync;

  // Слушатели изменений
  final List<VoidCallback> _tasksListeners = [];
  final List<VoidCallback> _shoppingListeners = [];
  final List<VoidCallback> _cleaningListeners = [];
  final List<VoidCallback> _roomMembersListeners = [];

  /// Начать синхронизацию для текущей комнаты
  void startSync(int roomId) {
    stopAllSync(); // Останавливаем предыдущую синхронизацию

    // Запускаем таймеры для каждого типа данных
    _startTasksSync(roomId);
    _startShoppingSync(roomId);
    _startCleaningSync(roomId);
    _startRoomMembersSync(roomId);

    notifyListeners();
  }

  /// Остановить всю синхронизацию
  void stopAllSync() {
    _stopTasksSync();
    _stopShoppingSync();
    _stopCleaningSync();
    _stopRoomMembersSync();

    notifyListeners();
  }

  // === Tasks Sync ===

  void _startTasksSync(int roomId) {
    _stopTasksSync();
    _isTasksSyncing = true;

    _tasksTimer = Timer.periodic(
      Duration(seconds: _tasksSyncInterval),
      (_) => _syncTasks(roomId),
    );

    // Первый запуск сразу
    _syncTasks(roomId);
  }

  void _stopTasksSync() {
    _tasksTimer?.cancel();
    _tasksTimer = null;
    _isTasksSyncing = false;
  }

  Future<void> _syncTasks(int roomId) async {
    try {
      for (final listener in _tasksListeners) {
        listener();
      }
      _lastTasksSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Tasks sync error: $e');
    }
  }

  void addTasksListener(VoidCallback listener) {
    _tasksListeners.add(listener);
  }

  void removeTasksListener(VoidCallback listener) {
    _tasksListeners.remove(listener);
  }

  // === Shopping Sync ===

  void _startShoppingSync(int roomId) {
    _stopShoppingSync();
    _isShoppingSyncing = true;

    _shoppingTimer = Timer.periodic(
      Duration(seconds: _shoppingSyncInterval),
      (_) => _syncShopping(roomId),
    );

    // Первый запуск сразу
    _syncShopping(roomId);
  }

  void _stopShoppingSync() {
    _shoppingTimer?.cancel();
    _shoppingTimer = null;
    _isShoppingSyncing = false;
  }

  Future<void> _syncShopping(int roomId) async {
    try {
      for (final listener in _shoppingListeners) {
        listener();
      }
      _lastShoppingSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Shopping sync error: $e');
    }
  }

  void addShoppingListener(VoidCallback listener) {
    _shoppingListeners.add(listener);
  }

  void removeShoppingListener(VoidCallback listener) {
    _shoppingListeners.remove(listener);
  }

  // === Cleaning Sync ===

  void _startCleaningSync(int roomId) {
    _stopCleaningSync();
    _isCleaningSyncing = true;

    _cleaningTimer = Timer.periodic(
      Duration(seconds: _cleaningSyncInterval),
      (_) => _syncCleaning(roomId),
    );

    // Первый запуск сразу
    _syncCleaning(roomId);
  }

  void _stopCleaningSync() {
    _cleaningTimer?.cancel();
    _cleaningTimer = null;
    _isCleaningSyncing = false;
  }

  Future<void> _syncCleaning(int roomId) async {
    try {
      for (final listener in _cleaningListeners) {
        listener();
      }
      _lastCleaningSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Cleaning sync error: $e');
    }
  }

  void addCleaningListener(VoidCallback listener) {
    _cleaningListeners.add(listener);
  }

  void removeCleaningListener(VoidCallback listener) {
    _cleaningListeners.remove(listener);
  }

  // === Room Members Sync ===

  void _startRoomMembersSync(int roomId) {
    _stopRoomMembersSync();
    _isRoomMembersSyncing = true;

    _roomMembersTimer = Timer.periodic(
      Duration(seconds: _roomMembersSyncInterval),
      (_) => _syncRoomMembers(roomId),
    );

    // Первый запуск сразу
    _syncRoomMembers(roomId);
  }

  void _stopRoomMembersSync() {
    _roomMembersTimer?.cancel();
    _roomMembersTimer = null;
    _isRoomMembersSyncing = false;
  }

  Future<void> _syncRoomMembers(int roomId) async {
    try {
      for (final listener in _roomMembersListeners) {
        listener();
      }
      _lastRoomMembersSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Room members sync error: $e');
    }
  }

  void addRoomMembersListener(VoidCallback listener) {
    _roomMembersListeners.add(listener);
  }

  void removeRoomMembersListener(VoidCallback listener) {
    _roomMembersListeners.remove(listener);
  }

  // === Getters ===

  bool get isTasksSyncing => _isTasksSyncing;
  bool get isShoppingSyncing => _isShoppingSyncing;
  bool get isCleaningSyncing => _isCleaningSyncing;
  bool get isRoomMembersSyncing => _isRoomMembersSyncing;

  DateTime? get lastTasksSync => _lastTasksSync;
  DateTime? get lastShoppingSync => _lastShoppingSync;
  DateTime? get lastCleaningSync => _lastCleaningSync;
  DateTime? get lastRoomMembersSync => _lastRoomMembersSync;

  @override
  void dispose() {
    stopAllSync();
    super.dispose();
  }
}
