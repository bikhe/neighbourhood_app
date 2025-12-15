import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../models/room.dart';
import '../../models/room_member.dart';
import 'rooms_list_screen.dart';

class RoomSettingsScreen extends StatefulWidget {
  const RoomSettingsScreen({super.key});

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  List<RoomMember> _members = [];
  Room? _room;
  bool _isLoading = true;
  RoomMember? _currentUserMember;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final roomService = context.read<RoomService>();
      final apiService = context.read<ApiService>();
      final authService = context.read<AuthService>();

      if (roomService.currentRoomId == null) return;

      final members =
          await apiService.getRoomMembers(roomService.currentRoomId!);
      final rooms = await apiService.getRooms();

      Room? currentRoom;
      for (var r in rooms) {
        if (r.id == roomService.currentRoomId) {
          currentRoom = r;
          break;
        }
      }

      RoomMember? currentMember;
      if (authService.currentUser != null) {
        for (var m in members) {
          if (m.user.id == authService.currentUser!.id) {
            currentMember = m;
            break;
          }
        }
      }

      setState(() {
        _members = members;
        _room = currentRoom;
        _currentUserMember = currentMember;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _kickUser(RoomMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Исключить участника?'),
        content:
            Text('Вы уверены, что хотите исключить ${member.user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Исключить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final roomService = context.read<RoomService>();
      final apiService = context.read<ApiService>();

      await apiService.kickUser(roomService.currentRoomId!, member.user.id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Участник исключен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _toggleBanUser(RoomMember member) async {
    final isBanning = !member.isBanned;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBanning ? 'Забанить?' : 'Разбанить?'),
        content: Text(
          isBanning
              ? 'Участник ${member.user.fullName} не сможет вернуться в комнату.'
              : 'Участник ${member.user.fullName} сможет снова присоединиться.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isBanning ? Theme.of(context).colorScheme.error : null,
            ),
            child: Text(isBanning ? 'Забанить' : 'Разбанить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final roomService = context.read<RoomService>();
      final apiService = context.read<ApiService>();

      if (isBanning) {
        await apiService.banUser(roomService.currentRoomId!, member.user.id);
      } else {
        await apiService.unbanUser(roomService.currentRoomId!, member.user.id);
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(isBanning ? 'Участник забанен' : 'Участник разбанен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Покинуть комнату?'),
        content: const Text('Вы сможете присоединиться снова по коду.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final roomService = context.read<RoomService>();
      final apiService = context.read<ApiService>();

      await apiService.leaveRoom(roomService.currentRoomId!);
      await roomService.clearCurrentRoom();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoomsListScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить комнату?'),
        content: const Text('Все данные будут удалены безвозвратно!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final roomService = context.read<RoomService>();
      final apiService = context.read<ApiService>();

      await apiService.deleteRoom(roomService.currentRoomId!);
      await roomService.clearCurrentRoom();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoomsListScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Комната удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showRoomCode() {
    if (_room == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Код комнаты'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Поделитесь этим кодом:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    _room!.code,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _room!.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Код скопирован')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomService = context.watch<RoomService>();
    final isOwner = _currentUserMember?.isOwner ?? false;

    final activeMembers = _members.where((m) => !m.isBanned).toList();
    final bannedMembers = _members.where((m) => m.isBanned).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки комнаты'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.home,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  roomService.currentRoomName ?? 'Комната',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${activeMembers.length} активных участников'),
                          if (_room != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: _showRoomCode,
                                icon: const Icon(Icons.share),
                                label: const Text('Поделиться кодом'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Участники (${activeMembers.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...activeMembers
                      .map((member) => _buildMemberTile(member, isOwner)),
                  if (bannedMembers.isNotEmpty && isOwner) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Забаненные (${bannedMembers.length})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...bannedMembers
                        .map((member) => _buildMemberTile(member, isOwner)),
                  ],
                  const SizedBox(height: 24),
                  if (!isOwner)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        onPressed: _leaveRoom,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Покинуть комнату'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  if (isOwner)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: _deleteRoom,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Удалить комнату'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberTile(RoomMember member, bool canManage) {
    final canManageThis = canManage && !member.isOwner;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isBanned
              ? Theme.of(context).colorScheme.errorContainer
              : null,
          child: Text(member.user.firstName[0] + member.user.lastName[0]),
        ),
        title: Row(
          children: [
            Expanded(child: Text(member.user.fullName)),
            if (member.isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Владелец',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            if (member.isBanned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Забанен',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(member.user.contact),
        trailing: canManageThis
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'ban') {
                    _toggleBanUser(member);
                  } else if (value == 'kick') {
                    _kickUser(member);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'ban',
                    child: Row(
                      children: [
                        Icon(
                            member.isBanned ? Icons.check_circle : Icons.block),
                        const SizedBox(width: 12),
                        Text(member.isBanned ? 'Разбанить' : 'Забанить'),
                      ],
                    ),
                  ),
                  if (!member.isBanned)
                    const PopupMenuItem(
                      value: 'kick',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove),
                          SizedBox(width: 12),
                          Text('Исключить'),
                        ],
                      ),
                    ),
                ],
              )
            : null,
      ),
    );
  }
}
