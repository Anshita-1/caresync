import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Entry-point for background notification actions
@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse response) {
  ReminderNotificationService.onNotificationResponse?.call(response);
}

/// Types of medicine to choose appropriate icon
enum MedicineType { pill, syrup, injection }

/// Data model for a medicine reminder
class Reminder {
  int id;
  String name;
  MedicineType type;
  DateTime scheduledTime;
  bool acknowledged;
  int missedId;

  Reminder({
    required this.id,
    required this.name,
    required this.type,
    required this.scheduledTime,
    this.acknowledged = false,
    required this.missedId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'time': scheduledTime.toIso8601String(),
    'ack': acknowledged,
    'missedId': missedId,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    name: json['name'],
    type: MedicineType.values[json['type']],
    scheduledTime: DateTime.parse(json['time']),
    acknowledged: json['ack'],
    missedId: json['missedId'],
  );
}

/// Handles local notifications with action buttons
class ReminderNotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  // Dart callback invoked on both foreground & background taps
  static void Function(NotificationResponse)? onNotificationResponse;

  /// Initialize plugin, channels, permissions, and timezone data
  static Future<void> init() async {
    // 1️⃣ Timezone support
    tz.initializeTimeZones();

    // 2️⃣ Init settings (iOS asks permissions automatically)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 3️⃣ Initialize plugin with both foreground & background callbacks
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        onNotificationResponse?.call(resp);
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    // 4️⃣ Create Android channel
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'med_reminder_channel',
        'Medicine Reminders',
        description: 'Reminders to take your medicines',
        importance: Importance.max,
      ),
    );

    // 5️⃣ Request runtime permissions (Android 13+) & exact-alarm (Android 12+)
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  /// Schedule the primary and missed reminders
  static Future<void> scheduleReminder(Reminder r) async {
    // Primary reminder with action buttons
    final androidDetails = AndroidNotificationDetails(
      'med_reminder_channel',
      'Medicine Reminders',
      channelDescription: 'Reminders to take medicines',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'TAKEN',
          'Taken',
          cancelNotification: true,       // auto-dismiss
          showsUserInterface: true,       // ensure callback fires
        ),
        AndroidNotificationAction(
          'REMIND',
          'Remind in 3 mins',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );
    final notice = NotificationDetails(android: androidDetails);

    // Schedule main reminder
    await _notifications.zonedSchedule(
      r.id,
      'Medicine Reminder',
      'Time to take ${r.name}',
      tz.TZDateTime.from(r.scheduledTime, tz.local),
      notice,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: r.id.toString(),
    );

    // Missed reminder 15 minutes later
    final missedTime = r.scheduledTime.add(const Duration(minutes: 15));
    final androidMissed = AndroidNotificationDetails(
      'med_reminder_channel',
      'Missed Medicine',
      channelDescription: 'Missed medicine alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final missedNotice = NotificationDetails(android: androidMissed);

    await _notifications.zonedSchedule(
      r.missedId,
      'Missed Medicine',
      'You missed your medicine: ${r.name}',
      tz.TZDateTime.from(missedTime, tz.local),
      missedNotice,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: r.id.toString(),
    );
  }

  /// Cancel a scheduled notification by its ID
  static Future<void> cancel(int id) => _notifications.cancel(id);
}

/// Main screen for managing medicine reminders
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  DateTime? _pickedTime;
  MedicineType _pickedType = MedicineType.pill;
  List<Reminder> _reminders = [];
  late SharedPreferences _prefs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadPrefs();

    // ⚠️ Set callback **before** initializing so background taps find it
    ReminderNotificationService.onNotificationResponse =
        _handleNotificationResponse;
    ReminderNotificationService.init();

    // Periodic rebuild so statuses auto-update
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final data = _prefs.getStringList('med_reminders') ?? [];
    setState(() {
      _reminders =
          data.map((s) => Reminder.fromJson(json.decode(s))).toList();
    });
  }

  Future<void> _savePrefs() async {
    final list = _reminders.map((r) => json.encode(r.toJson())).toList();
    await _prefs.setStringList('med_reminders', list);
  }

  /// Handle notification taps/actions
  void _handleNotificationResponse(NotificationResponse resp) {
    final id = int.tryParse(resp.payload ?? '');
    if (id == null) return;
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    final r = _reminders[idx];

    if (resp.actionId == 'TAKEN') {
      setState(() => r.acknowledged = true);
      // Cancel both the main and missed notifications
      ReminderNotificationService.cancel(r.id);
      ReminderNotificationService.cancel(r.missedId);
      _savePrefs();
    } else if (resp.actionId == 'REMIND') {
      // Cancel the existing ones
      ReminderNotificationService.cancel(r.id);
      ReminderNotificationService.cancel(r.missedId);

      // Reschedule for 3 mins later
      final newTime = DateTime.now().add(const Duration(minutes: 3));
      final newId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final newMiss = newId + 1;
      final newRem = Reminder(
        id: newId,
        name: r.name,
        type: r.type,
        scheduledTime: newTime,
        missedId: newMiss,
      );
      setState(() => _reminders.add(newRem));
      _savePrefs();
      ReminderNotificationService.scheduleReminder(newRem);
    } else {
      // Body tap → treat as “Taken”
      setState(() => r.acknowledged = true);
      ReminderNotificationService.cancel(r.id);
      ReminderNotificationService.cancel(r.missedId);
      _savePrefs();
    }
  }

  /// Pick date & time for a new reminder
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _pickedTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  /// Add a new reminder
  Future<void> _addReminder() async {
    if (_nameCtrl.text.trim().isEmpty || _pickedTime == null) return;
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final missId = id + 1;
    final rem = Reminder(
      id: id,
      name: _nameCtrl.text.trim(),
      type: _pickedType,
      scheduledTime: _pickedTime!,
      missedId: missId,
    );
    setState(() => _reminders.add(rem));
    await _savePrefs();
    ReminderNotificationService.scheduleReminder(rem);
    _nameCtrl.clear();
    setState(() => _pickedTime = null);
  }

  /// Delete a reminder
  Future<void> _deleteReminder(Reminder r) async {
    ReminderNotificationService.cancel(r.id);
    ReminderNotificationService.cancel(r.missedId);
    setState(() => _reminders.remove(r));
    await _savePrefs();
  }

  /// Edit an existing reminder
  Future<void> _editReminder(Reminder r) async {
    final nameCtrl = TextEditingController(text: r.name);
    MedicineType tempType = r.type;
    DateTime? tempTime = r.scheduledTime;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            DropdownButton<MedicineType>(
              value: tempType,
              items: MedicineType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last)))
                  .toList(),
              onChanged: (v) => tempType = v!,
            ),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: tempTime!,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(tempTime!),
                );
                if (time == null) return;
                tempTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
              },
              child: const Text('Change Time'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                ReminderNotificationService.cancel(r.id);
                ReminderNotificationService.cancel(r.missedId);
                setState(() {
                  r.name = nameCtrl.text.trim();
                  r.type = tempType;
                  r.scheduledTime = tempTime!;
                  r.acknowledged = false;
                });
                _savePrefs();
                ReminderNotificationService.scheduleReminder(r);
                Navigator.pop(context);
              },
              child: const Text('Save'))
        ],
      ),
    );
  }

  /// Determine the current status
  String _getStatus(Reminder r) {
    final now = DateTime.now();
    if (r.acknowledged) return 'Taken';
    if (now.isAfter(r.scheduledTime.add(const Duration(minutes: 15)))) return 'Missed';
    if (now.isAfter(r.scheduledTime)) return 'Due';
    return 'Scheduled';
  }

  /// Map medicine type to icon
  IconData _iconForType(MedicineType t) {
    switch (t) {
      case MedicineType.pill:
        return Icons.medication;
      case MedicineType.syrup:
        return Icons.local_drink;
      case MedicineType.injection:
        return Icons.vaccines;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name')),
                    Row(
                      children: [
                        const Text('Type:'),
                        const SizedBox(width: 8),
                        DropdownButton<MedicineType>(
                          value: _pickedType,
                          items: MedicineType.values
                              .map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last)))
                              .toList(),
                          onChanged: (v) => setState(() => _pickedType = v!),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _pickDateTime,
                          child: Text(_pickedTime == null
                              ? 'Pick Time'
                              : DateFormat.yMd().add_jm().format(_pickedTime!)),
                        ),
                      ],
                    ),
                    ElevatedButton(onPressed: _addReminder, child: const Text('Set Reminder')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _reminders.isEmpty
                  ? const Center(child: Text('No reminders set.'))
                  : ListView.separated(
                itemCount: _reminders.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final r = _reminders[i];
                  return ListTile(
                    leading: Icon(_iconForType(r.type), color: Colors.blue),
                    title: Text(r.name),
                    subtitle: Text('${DateFormat.yMd().add_jm().format(r.scheduledTime)} • ${_getStatus(r)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editReminder(r)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteReminder(r)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
