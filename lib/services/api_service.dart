import 'dart:convert';
import 'dart:async'; // Для TimeoutException
import 'package:flutter/foundation.dart'; // Для debugPrint
import 'package:http/http.dart' as http;

import '../config.dart'; // Исправляет Undefined name 'Config'
import '../models/user.dart';
import '../models/task.dart';
import '../models/shopping_item.dart';
import '../models/cleaning_schedule.dart';
import '../models/message.dart';
import '../models/room.dart';
import '../models/room_member.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService;

  ApiService(this._authService);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authService.token}',
      };

  // === Rooms ===

  Future<List<Room>> getRooms() async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/rooms'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Room.fromJson(json)).toList();
    }
    throw Exception('Failed to load rooms');
  }

  Future<Room> createRoom(String name) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms'),
      headers: _headers,
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 201) {
      return Room.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create room');
  }

  Future<Room> joinRoom(String code) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/join'),
      headers: _headers,
      body: json.encode({'code': code.toUpperCase()}),
    );

    if (response.statusCode == 200) {
      return Room.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Комната не найдена');
    } else if (response.statusCode == 403) {
      throw Exception('Вы забанены в этой комнате');
    } else if (response.statusCode == 400) {
      throw Exception('Вы уже участник этой комнаты');
    }
    throw Exception('Failed to join room');
  }

  Future<void> leaveRoom(int roomId) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/leave'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to leave room');
    }
  }

  Future<void> deleteRoom(int roomId) async {
    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/rooms/$roomId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete room');
    }
  }

  Future<List<RoomMember>> getRoomMembers(int roomId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/members'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RoomMember.fromJson(json)).toList();
    }
    throw Exception('Failed to load members');
  }

  Future<void> banUser(int roomId, int userId) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/ban/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to ban user');
    }
  }

  Future<void> unbanUser(int roomId, int userId) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/unban/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unban user');
    }
  }

  Future<void> kickUser(int roomId, int userId) async {
    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/kick/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to kick user');
    }
  }

  // === Users ===

  Future<List<User>> getUsers(int roomId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/users'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('Failed to load users');
  }

  // === Tasks ===

  Future<List<Task>> getTasks(int roomId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/tasks'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  Future<Task> createTask(
      int roomId, String title, String? description, int assigneeId) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/tasks'),
      headers: _headers,
      body: json.encode({
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
      }),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create task');
  }

  Future<Task> updateTask(int roomId, int id,
      {String? title,
      String? description,
      int? assigneeId,
      bool? completed}) async {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (assigneeId != null) data['assignee_id'] = assigneeId;
    if (completed != null) data['completed'] = completed;

    final response = await http.put(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/tasks/$id'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update task');
  }

  Future<void> deleteTask(int roomId, int id) async {
    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/tasks/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  // === Shopping ===

  Future<List<ShoppingItem>> getShoppingItems(int roomId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/shopping'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ShoppingItem.fromJson(json)).toList();
    }
    throw Exception('Failed to load shopping items');
  }

  Future<ShoppingItem> createShoppingItem(
      int roomId, String name, String? quantity) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/shopping'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 201) {
      return ShoppingItem.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create shopping item');
  }

  Future<ShoppingItem> updateShoppingItem(int roomId, int id,
      {String? name, String? quantity, bool? purchased}) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (quantity != null) data['quantity'] = quantity;
    if (purchased != null) data['purchased'] = purchased;

    final response = await http.put(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/shopping/$id'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return ShoppingItem.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update shopping item');
  }

  Future<void> deleteShoppingItem(int roomId, int id) async {
    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/shopping/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete shopping item');
    }
  }

  // === Cleaning ===

  Future<List<CleaningSchedule>> getCleaningSchedule(int roomId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/cleaning'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CleaningSchedule.fromJson(json)).toList();
    }
    throw Exception('Failed to load cleaning schedule');
  }

  Future<CleaningSchedule> createCleaningSchedule(
      int roomId, int userId, int dayOfWeek, String area) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/cleaning'),
      headers: _headers,
      body: json.encode({
        'user_id': userId,
        'day_of_week': dayOfWeek,
        'area': area,
      }),
    );

    if (response.statusCode == 201) {
      return CleaningSchedule.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create cleaning schedule');
  }

  Future<CleaningSchedule> updateCleaningSchedule(int roomId, int id,
      {int? userId, int? dayOfWeek, String? area}) async {
    final Map<String, dynamic> data = {};
    if (userId != null) data['user_id'] = userId;
    if (dayOfWeek != null) data['day_of_week'] = dayOfWeek;
    if (area != null) data['area'] = area;

    final response = await http.put(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/cleaning/$id'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return CleaningSchedule.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update cleaning schedule');
  }

  Future<void> deleteCleaningSchedule(int roomId, int id) async {
    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/cleaning/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete cleaning schedule');
    }
  }

  // === Messages ===

  Future<List<Message>> getMessages(int roomId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/messages'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    }
    throw Exception('Failed to load messages');
  }

  Future<Message> sendMessage(int roomId, String content) async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/rooms/$roomId/messages'),
      headers: _headers,
      body: json.encode({
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      return Message.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to send message');
  }

  Future<List<Message>> pollMessages(int roomId,
      {int lastMessageId = 0, int timeout = 25}) async {
    try {
      final response = await http
          .get(
        Uri.parse(
            '${Config.apiUrl}/rooms/$roomId/messages/poll?last_message_id=$lastMessageId&timeout=$timeout'),
        headers: _headers,
      )
          .timeout(
        Duration(seconds: timeout + 5),
        onTimeout: () {
          return http.Response('[]', 200);
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Poll error: $e');
      return [];
    }
  }
}
