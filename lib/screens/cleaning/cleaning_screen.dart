import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/room_service.dart';
import '../../models/cleaning_schedule.dart';
import '../../models/user.dart';

class CleaningScreen extends StatefulWidget {
  const CleaningScreen({super.key});

  @override
  State<CleaningScreen> createState() => CleaningScreenState();
}

class CleaningScreenState extends State<CleaningScreen>
    with AutomaticKeepAliveClientMixin {
  List<CleaningSchedule> _schedules = [];
  List<User> _users = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData(silent: true);
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void onScreenVisible() {
    _loadData(silent: true);
  }

  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      if (roomService.currentRoomId == null) return;

      final schedules =
          await apiService.getCleaningSchedule(roomService.currentRoomId!);
      final users = await apiService.getUsers(roomService.currentRoomId!);

      if (mounted) {
        setState(() {
          _schedules = schedules;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSchedule(CleaningSchedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text(
            'Вы уверены, что хотите удалить дежурство по уборке "${schedule.area}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      await apiService.deleteCleaningSchedule(
          roomService.currentRoomId!, schedule.id);
      _loadData(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись удалена')),
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

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        users: _users,
        onScheduleAdded: () => _loadData(silent: true),
      ),
    );
  }

  void _showEditScheduleDialog(CleaningSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => EditScheduleDialog(
        schedule: schedule,
        users: _users,
        onScheduleUpdated: () => _loadData(silent: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadData(),
        child: _schedules.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(
                    Icons.cleaning_services_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'График уборки не составлен',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы добавить запись',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : _buildScheduleTable(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  Widget _buildScheduleTable() {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];

    final scheduleByDay = <int, List<CleaningSchedule>>{};
    for (var schedule in _schedules) {
      scheduleByDay.putIfAbsent(schedule.dayOfWeek, () => []).add(schedule);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, dayIndex) {
        final daySchedules = scheduleByDay[dayIndex] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  days[dayIndex],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (daySchedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Нет записей',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...daySchedules.map((schedule) {
                  final user = _users.firstWhere(
                    (u) => u.id == schedule.userId,
                    orElse: () => User(
                      id: 0,
                      username: 'unknown',
                      firstName: 'Неизвестно',
                      lastName: '',
                      birthDate: '',
                      contact: '',
                      createdAt: DateTime.now(),
                    ),
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.firstName[0]),
                    ),
                    title: Text(schedule.area),
                    subtitle: Text(user.fullName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditScheduleDialog(schedule),
                          tooltip: 'Редактировать',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteSchedule(schedule),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: 'Удалить',
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class AddScheduleDialog extends StatefulWidget {
  final List<User> users;
  final VoidCallback onScheduleAdded;

  const AddScheduleDialog({
    super.key,
    required this.users,
    required this.onScheduleAdded,
  });

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();

  User? _selectedUser;
  int _selectedDay = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _createSchedule() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      await apiService.createCleaningSchedule(
        roomService.currentRoomId!,
        _selectedUser!.id,
        _selectedDay,
        _areaController.text.trim(),
      );

      if (mounted) {
        widget.onScheduleAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись добавлена')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье'
    ];

    return AlertDialog(
      title: const Text('Добавить запись'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'День недели',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: List.generate(7, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(days[index]),
                  );
                }).toList(),
                onChanged: (day) {
                  setState(() => _selectedDay = day!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Зона уборки *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cleaning_services_outlined),
                  hintText: 'Например: Кухня, Ванная, Коридор',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите зону уборки';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                value: _selectedUser,
                decoration: const InputDecoration(
                  labelText: 'Ответственный *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: widget.users.map((user) {
                  return DropdownMenuItem(
                    value: user,
                    child: Text(user.fullName),
                  );
                }).toList(),
                onChanged: (user) {
                  setState(() => _selectedUser = user);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите ответственного';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _createSchedule,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Добавить'),
        ),
      ],
    );
  }
}

class EditScheduleDialog extends StatefulWidget {
  final CleaningSchedule schedule;
  final List<User> users;
  final VoidCallback onScheduleUpdated;

  const EditScheduleDialog({
    super.key,
    required this.schedule,
    required this.users,
    required this.onScheduleUpdated,
  });

  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _areaController;
  late User? _selectedUser;
  late int _selectedDay;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(text: widget.schedule.area);
    _selectedDay = widget.schedule.dayOfWeek;
    _selectedUser = widget.users.firstWhere(
      (u) => u.id == widget.schedule.userId,
      orElse: () => widget.users.first,
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _updateSchedule() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      await apiService.updateCleaningSchedule(
        roomService.currentRoomId!,
        widget.schedule.id,
        userId: _selectedUser!.id,
        dayOfWeek: _selectedDay,
        area: _areaController.text.trim(),
      );

      if (mounted) {
        widget.onScheduleUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись обновлена')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье'
    ];

    return AlertDialog(
      title: const Text('Редактировать запись'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'День недели',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: List.generate(7, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(days[index]),
                  );
                }).toList(),
                onChanged: (day) {
                  setState(() => _selectedDay = day!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Зона уборки *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cleaning_services_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите зону уборки';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                value: _selectedUser,
                decoration: const InputDecoration(
                  labelText: 'Ответственный *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: widget.users.map((user) {
                  return DropdownMenuItem(
                    value: user,
                    child: Text(user.fullName),
                  );
                }).toList(),
                onChanged: (user) {
                  setState(() => _selectedUser = user);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите ответственного';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _updateSchedule,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
