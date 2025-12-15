import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/room_service.dart';

import 'tasks/tasks_screen.dart';
import 'shopping/shopping_screen.dart';
import 'chat/chat_screen.dart';
import 'cleaning/cleaning_screen.dart';
import 'roommates/roommates_screen.dart';

import 'rooms/rooms_list_screen.dart';
import 'rooms/room_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _tasksKey = GlobalKey<TasksScreenState>();
  final _shoppingKey = GlobalKey<ShoppingScreenState>();
  final _chatKey = GlobalKey();
  final _cleaningKey = GlobalKey<CleaningScreenState>();
  final _roommatesKey = GlobalKey<RoommatesScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TasksScreen(key: _tasksKey),
      ShoppingScreen(key: _shoppingKey),
      ChatScreen(key: _chatKey),
      CleaningScreen(key: _cleaningKey),
      RoommatesScreen(key: _roommatesKey),
    ];
  }

  void _refreshCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        _tasksKey.currentState?.refresh();
        break;
      case 1:
        _shoppingKey.currentState?.refresh();
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Чат обновляется автоматически'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 3:
        _cleaningKey.currentState?.refresh();
        break;
      case 4:
        _roommatesKey.currentState?.refresh();
        break;
    }
  }

  void _changeRoom() async {
    final roomService = context.read<RoomService>();
    await roomService.clearCurrentRoom();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoomsListScreen()),
        (route) => false,
      );
    }
  }

  void _openRoomSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoomSettingsScreen()),
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<RoomService>().clearCurrentRoom();
      await context.read<AuthService>().logout();
    }
  }

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
    _notifyScreenVisible(index);
  }

  void _notifyScreenVisible(int index) {
    switch (index) {
      case 0:
        _tasksKey.currentState?.onScreenVisible();
        break;
      case 1:
        _shoppingKey.currentState?.onScreenVisible();
        break;
      case 2:
        break;
      case 3:
        _cleaningKey.currentState?.onScreenVisible();
        break;
      case 4:
        _roommatesKey.currentState?.onScreenVisible();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomService = context.watch<RoomService>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Roommate App'),
            if (roomService.currentRoomName != null)
              Text(
                roomService.currentRoomName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _refreshCurrentScreen,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки комнаты',
            onPressed: _openRoomSettings,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Ещё',
            onSelected: (value) {
              switch (value) {
                case 'change_room':
                  _changeRoom();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_room',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz),
                    SizedBox(width: 12),
                    Text('Сменить комнату'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Покупки',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Чат',
          ),
          NavigationDestination(
            icon: Icon(Icons.cleaning_services_outlined),
            selectedIcon: Icon(Icons.cleaning_services),
            label: 'Уборка',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Жильцы',
          ),
        ],
      ),
    );
  }
}
