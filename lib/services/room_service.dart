import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RoomService extends ChangeNotifier {
  int? _currentRoomId;
  String? _currentRoomName;

  int? get currentRoomId => _currentRoomId;
  String? get currentRoomName => _currentRoomName;
  bool get hasActiveRoom => _currentRoomId != null;

  RoomService() {
    _loadCurrentRoom();
  }

  Future<void> _loadCurrentRoom() async {
    final prefs = await SharedPreferences.getInstance();
    _currentRoomId = prefs.getInt('current_room_id');
    _currentRoomName = prefs.getString('current_room_name');
    notifyListeners();
  }

  Future<void> setCurrentRoom(int roomId, String roomName) async {
    _currentRoomId = roomId;
    _currentRoomName = roomName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_room_id', roomId);
    await prefs.setString('current_room_name', roomName);

    notifyListeners();
  }

  Future<void> clearCurrentRoom() async {
    _currentRoomId = null;
    _currentRoomName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_room_id');
    await prefs.remove('current_room_name');

    notifyListeners();
  }
}
