import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(CareSyncApp());
}

// Global variable to simulate language selection.
String selectedLanguage = "English";

// A simple localization helper that returns text based on selected language.
String localizedText(String key) {
  Map<String, Map<String, String>> texts = {
    "appTitle": {"English": "CareSync", "Hindi": "केयरसिंक", "Marathi": "केयरसिंक"},
    "login": {"English": "Login", "Hindi": "लॉग इन", "Marathi": "लॉगिन"},
    "register": {"English": "Register", "Hindi": "रजिस्टर", "Marathi": "नोंदणी"},
    "username": {"English": "Username", "Hindi": "उपयोगकर्ता नाम", "Marathi": "वापरकर्तानाव"},
    "password": {"English": "Password", "Hindi": "पासवर्ड", "Marathi": "पासवर्ड"},
  };

  return texts[key]?[selectedLanguage] ?? key;
}

class CareSyncApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: localizedText("appTitle"),
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/home': (context) => HomeScreen(),
        '/adminHome': (context) => AdminHomeScreen(),
        '/orderHistory': (context) => OrderHistoryPage(),
      },
    );
  }
}

/// ------------------------------
/// Authentication Screens
/// ------------------------------

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

// Simple login: if user enters "admin" for both username and password, they are treated as an admin/doctor.
class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void login() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    // In a real app, you would validate against a backend.
    if (username == "admin" && password == "admin") {
      Navigator.pushReplacementNamed(context, '/adminHome');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(localizedText("login"))),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: localizedText("username")),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: localizedText("password")),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: Text(localizedText("login")),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text(localizedText("register")),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

// Registration page with basic fields. Replace this with real registration logic as needed.
class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void register() {
    // Registration logic would be implemented here.
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(localizedText("register"))),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: localizedText("username")),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: localizedText("password")),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: register,
              child: Text(localizedText("register")),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// Main Home Screen for Normal Users
/// ------------------------------

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// The home screen uses a bottom navigation bar to switch between functionalities.
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _tabs = [
    UploadReportsPage(),
    RemindersPage(),
    ChatBotPage(),
    VoiceAssistantPage(),
    ChemistsPage(),
    AppointmentsPage(),
    VideoCallRequestPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/');
  }

  void _changeLanguage(String lang) {
    setState(() {
      selectedLanguage = lang;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Language changed to $lang"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(localizedText("appTitle"))),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("CareSync Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: Text("Order History"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryPage()));
              },
            ),
            ListTile(
              title: Text("Language"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Select Language"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text("English"),
                            onTap: () {
                              _changeLanguage("English");
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text("Hindi"),
                            onTap: () {
                              _changeLanguage("Hindi");
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text("Marathi"),
                            onTap: () {
                              _changeLanguage("Marathi");
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            ListTile(
              title: Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: "Reminders"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "ChatBot"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Voice"),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy), label: "Chemists"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Appointments"),
          BottomNavigationBarItem(icon: Icon(Icons.video_call), label: "Video Call"),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}

/// ------------------------------
/// Functional Pages for Users
/// ------------------------------

/// 1. Upload Reports & Prescription
class UploadReportsPage extends StatefulWidget {
  @override
  _UploadReportsPageState createState() => _UploadReportsPageState();
}

class _UploadReportsPageState extends State<UploadReportsPage> {
  String? _fileName;

  Future<void> _pickFile() async {
    // Uses file_picker package to simulate file upload.
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File $_fileName uploaded successfully"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Upload Reports & Prescriptions"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickFile,
            child: Text("Upload File"),
          ),
          SizedBox(height: 20),
          _fileName != null ? Text("Uploaded File: $_fileName") : Container(),
        ],
      ),
    );
  }
}

/// 2. Reminders - set medication reminders based on the latest prescription.
class RemindersPage extends StatefulWidget {
  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  DateTime? _selectedTime;

  Future<void> _pickTime() async {
    TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      final now = DateTime.now();
      setState(() {
        _selectedTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reminder set for ${DateFormat.jm().format(_selectedTime!)}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Set Reminders based on your latest prescription"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickTime,
            child: Text("Set Reminder"),
          ),
          SizedBox(height: 20),
          _selectedTime != null
              ? Text("Reminder at: ${DateFormat.jm().format(_selectedTime!)}")
              : Container(),
        ],
      ),
    );
  }
}

/// 3. ChatBot - user enters symptoms and gets a suggestion.
class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _symptomsController = TextEditingController();
  String _botResponse = "";

  void _getSuggestion() {
    String symptoms = _symptomsController.text.trim();
    if (symptoms.isNotEmpty) {
      setState(() {
        // A dummy response – replace with a call to an AI service if needed.
        _botResponse = "Based on your symptoms, please consider seeing a doctor if they persist.";
      });
    } else {
      setState(() {
        _botResponse = "Please enter your symptoms.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("ChatBot - Enter your symptoms below:"),
          SizedBox(height: 10),
          TextField(
            controller: _symptomsController,
            decoration: InputDecoration(hintText: "Describe your symptoms"),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _getSuggestion,
            child: Text("Get Suggestion"),
          ),
          SizedBox(height: 20),
          Text(_botResponse, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// 4. Voice Assistant - simulate voice command control.
class VoiceAssistantPage extends StatefulWidget {
  @override
  _VoiceAssistantPageState createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage> {
  String _status = "Inactive";

  // Replace this with real voice processing (using speech_to_text or similar packages).
  void _activateVoiceAssistant() {
    setState(() {
      _status = "Voice assistant activated (simulated)";
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Voice command processed"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Voice Assistant", style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _activateVoiceAssistant,
            child: Text("Activate Voice Assistant"),
          ),
          SizedBox(height: 20),
          Text(_status),
        ],
      ),
    );
  }
}

/// 5. Chemists - display nearby chemists and allow sending prescription via WhatsApp/SMS.
class ChemistsPage extends StatelessWidget {
  // Dummy chemist list.
  final List<Map<String, String>> chemists = [
    {"name": "Chemist A", "phone": "+1234567890"},
    {"name": "Chemist B", "phone": "+0987654321"},
    {"name": "Chemist C", "phone": "+1122334455"},
  ];

  void _sendPrescription(String phone, BuildContext context) async {
    // Example: launch WhatsApp using url_launcher.
    String message = "Please find my prescription attached.";
    String url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    // Check if URL can be launched and then launch it.
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch WhatsApp"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chemists.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(chemists[index]["name"] ?? ""),
          subtitle: Text("Phone: ${chemists[index]["phone"]}"),
          trailing: IconButton(
            icon: Icon(Icons.message),
            onPressed: () => _sendPrescription(chemists[index]["phone"]!, context),
          ),
        );
      },
    );
  }
}

/// 6. Appointments - book an appointment with a doctor.
class AppointmentsPage extends StatefulWidget {
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final TextEditingController _doctorNameController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    DateTime? date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(now.year + 1)
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _bookAppointment() {
    if (_doctorNameController.text.isNotEmpty && _selectedDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Appointment booked with Dr. ${_doctorNameController.text} on ${DateFormat.yMMMd().format(_selectedDate!)}")
          )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter doctor name and select a date"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Book an Appointment"),
          SizedBox(height: 10),
          TextField(
            controller: _doctorNameController,
            decoration: InputDecoration(labelText: "Doctor's Name"),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickDate,
            child: Text("Select Date"),
          ),
          SizedBox(height: 10),
          _selectedDate != null
              ? Text("Selected: ${DateFormat.yMMMd().format(_selectedDate!)}")
              : Container(),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _bookAppointment,
            child: Text("Book Appointment"),
          )
        ],
      ),
    );
  }
}

/// 7. Video Call Request - users request a video call with a doctor.
class VideoCallRequestPage extends StatefulWidget {
  @override
  _VideoCallRequestPageState createState() => _VideoCallRequestPageState();
}

class _VideoCallRequestPageState extends State<VideoCallRequestPage> {
  bool _requested = false;
  DateTime? _scheduledTime; // In a real app, the doctor would set this.

  void _requestVideoCall() {
    setState(() {
      _requested = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Video call requested. Awaiting doctor's schedule."))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _requested
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Video call requested."),
          _scheduledTime != null
              ? Text("Scheduled at: ${DateFormat.jm().format(_scheduledTime!)}")
              : Text("Waiting for doctor to schedule the call."),
        ],
      )
          : ElevatedButton(
        onPressed: _requestVideoCall,
        child: Text("Request Video Call"),
      ),
    );
  }
}

/// 8. Order History - view chemist/medicine orders; mark as complete or send a reminder.
class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Map<String, dynamic>> orders = [
    {"order": "Order 1 - Delivered", "status": "completed"},
    {"order": "Order 2 - Pending", "status": "pending"},
    {"order": "Order 3 - Late", "status": "late"},
  ];

  void _markComplete(int index) {
    setState(() {
      orders[index]["status"] = "completed";
      orders[index]["order"] = orders[index]["order"]
          .toString()
          .replaceAll("Pending", "Completed")
          .replaceAll("Late", "Completed");
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order marked as completed"))
    );
  }

  void _sendReminder(int index) async {
    String phone = "+1234567890"; // Dummy chemist number.
    String message = "Reminder: Please update me on the status of my order.";
    String url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch messaging app"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order History")),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          bool isPendingOrLate = (orders[index]["status"] == "pending" || orders[index]["status"] == "late");
          return ListTile(
            title: Text(orders[index]["order"]),
            trailing: isPendingOrLate
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () => _markComplete(index),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendReminder(index),
                ),
              ],
            )
                : null,
          );
        },
      ),
    );
  }
}

/// ------------------------------
/// Admin/Doctor Screens
/// ------------------------------

/// Admin Home Screen: For admin/doctor login.
class AdminHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAppointmentsPage()));
              },
              child: Text("View Appointments"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminVideoCallsPage()));
              },
              child: Text("View Video Call Requests"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin Appointments Page - list appointments booked by users.
class AdminAppointmentsPage extends StatelessWidget {
  final List<String> appointments = [
    "Appointment: User1 with Dr. Smith on 2025-05-10",
    "Appointment: User2 with Dr. Jones on 2025-05-11",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Appointments")),
      body: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(appointments[index]),
          );
        },
      ),
    );
  }
}

/// Admin Video Calls Page - view and schedule video call requests.
class AdminVideoCallsPage extends StatefulWidget {
  @override
  _AdminVideoCallsPageState createState() => _AdminVideoCallsPageState();
}

class _AdminVideoCallsPageState extends State<AdminVideoCallsPage> {
  final List<Map<String, dynamic>> videoCallRequests = [
    {"user": "User1", "requested": true, "scheduledTime": null},
    {"user": "User2", "requested": true, "scheduledTime": null},
  ];

  Future<void> _scheduleCall(int index) async {
    TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      final now = DateTime.now();
      DateTime scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      setState(() {
        videoCallRequests[index]["scheduledTime"] = scheduledTime;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Video call scheduled for ${DateFormat.jm().format(scheduledTime)}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Video Call Requests")),
      body: ListView.builder(
        itemCount: videoCallRequests.length,
        itemBuilder: (context, index) {
          DateTime? scheduled = videoCallRequests[index]["scheduledTime"];
          return ListTile(
            title: Text("Video Call Request from ${videoCallRequests[index]["user"]}"),
            subtitle: scheduled != null ? Text("Scheduled at: ${DateFormat.jm().format(scheduled)}") : null,
            trailing: scheduled == null
                ? ElevatedButton(
              onPressed: () => _scheduleCall(index),
              child: Text("Schedule"),
            )
                : null,
          );
        },
      ),
    );
  }
}