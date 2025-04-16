import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Model representing a medicine reminder.
class Reminder {
  String medicineName;
  DateTime scheduledTime;
  bool acknowledged;
  int notificationId;    // ID for the scheduled reminder notification.
  int missedNotificationId; // ID for the missed reminder notification.

  Reminder({
    required this.medicineName,
    required this.scheduledTime,
    this.acknowledged = false,
    required this.notificationId,
    required this.missedNotificationId,
  });
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final List<Reminder> _reminders = [];
  DateTime? _selectedTime;
  bool _isUploading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the UI every 30 seconds to update reminder statuses.
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _timeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// Prompts the user to pick both a date and a time.
  Future<void> _pickDateTime() async {
    // Pick date.
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // adjust if past dates should be allowed
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Pick time.
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        // Combine date and time.
        DateTime combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _selectedTime = combined;
          _timeController.text = DateFormat.yMd().add_jm().format(combined);
        });
      }
    }
  }

  // Checks for duplicate reminders based on medicine name and hour-minute.
  bool _isDuplicate(String medicine, DateTime time) {
    for (var r in _reminders) {
      if (r.medicineName.toLowerCase() == medicine.toLowerCase() &&
          r.scheduledTime.hour == time.hour &&
          r.scheduledTime.minute == time.minute) {
        return true;
      }
    }
    return false;
  }

  /// Adds a new reminder, schedules notifications and prevents duplicates.
  Future<void> _addReminder() async {
    String medicine = _medicineController.text.trim();
    if (medicine.isEmpty || _selectedTime == null) {
      _showPopup("Error", "Please enter a medicine name and select date & time.");
      return;
    }
    if (_isDuplicate(medicine, _selectedTime!)) {
      _showPopup("Duplicate", "A reminder for this medicine at that time already exists.");
      return;
    }

    // Generate notification IDs using current timestamp.
    int idBase = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    int primaryId = idBase;
    int missedId = idBase + 1;

    Reminder newReminder = Reminder(
      medicineName: medicine,
      scheduledTime: _selectedTime!,
      notificationId: primaryId,
      missedNotificationId: missedId,
    );

    setState(() {
      _reminders.add(newReminder);
    });

    // Schedule the primary reminder.
    await NotificationService.scheduleNotification(
      id: primaryId,
      title: "Medicine Reminder",
      body: "Time to take your medicine: $medicine",
      scheduledTime: newReminder.scheduledTime,
    );

    // Schedule the missed reminder 10 minutes later.
    DateTime missedTime = newReminder.scheduledTime.add(const Duration(minutes: 10));
    await NotificationService.scheduleNotification(
      id: missedId,
      title: "Missed Reminder",
      body: "You missed your medicine: $medicine",
      scheduledTime: missedTime,
    );

    _showPopup("Success", "Reminder set successfully.");
    _medicineController.clear();
    _timeController.clear();
    _selectedTime = null;
  }

  /// Acknowledges a reminder and cancels the missed notification.
  Future<void> _acknowledgeReminder(Reminder reminder) async {
    if (!reminder.acknowledged) {
      reminder.acknowledged = true;
      await NotificationService.cancelNotification(reminder.missedNotificationId);
      _showPopup("Acknowledged", "You have acknowledged the reminder for ${reminder.medicineName}.");
      setState(() {});
    }
  }

  /// Determines the current status of a reminder.
  String _getStatus(Reminder reminder) {
    final now = DateTime.now();
    if (reminder.acknowledged) return "Acknowledged";
    if (now.isAfter(reminder.scheduledTime.add(const Duration(minutes: 10)))) return "Missed";
    if (now.isAfter(reminder.scheduledTime)) return "Pending (Due)";
    return "Scheduled";
  }

  /// Custom animated pop-up dialog.
  Future<void> _showPopup(String title, String message) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Popup",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("OK"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// Builds a card tile for the given reminder.
  Widget _buildReminderTile(Reminder reminder) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Color(0xFF4A90E2), size: 40),
        title: Text(
          reminder.medicineName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Time: ${DateFormat.jm().format(reminder.scheduledTime)}\nStatus: ${_getStatus(reminder)}",
        ),
        trailing: (!reminder.acknowledged && DateTime.now().isAfter(reminder.scheduledTime))
            ? ElevatedButton(
          onPressed: () => _acknowledgeReminder(reminder),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(100, 40),
          ),
          child: const Text("Acknowledge"),
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background matching the app theme.
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Reminder Form Card.
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF2F8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _medicineController,
                            decoration: InputDecoration(
                              labelText: "Enter Medicine Name",
                              prefixIcon: const Icon(Icons.medical_services),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _timeController,
                            readOnly: true,
                            onTap: _pickDateTime,
                            decoration: InputDecoration(
                              labelText: "Select Date & Time",
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _isUploading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            onPressed: _addReminder,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text("Set Reminder"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // List of Reminders.
                const SizedBox(height: 20),
                _reminders.isEmpty
                    ? const Center(
                  child: Text(
                    "No reminders set.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    Reminder reminder = _reminders[index];
                    return _buildReminderTile(reminder);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
