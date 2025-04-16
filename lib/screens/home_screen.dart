// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'upload_report_screen.dart';
import 'reminder_screen.dart';
import 'chatbot_screen.dart';
import 'voice_assistant_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Locale) setLocale;
  final void Function(ThemeMode) setThemeMode;

  const HomeScreen({
    Key? key,
    required this.setLocale,
    required this.setThemeMode,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Translation keys for AppBar titles
  static const _appBarKeys = [
    'upload_report',
    'set_reminders',
    'chatbot',
    'voice_assistant',
    'profile',
  ];

  void _onItemTapped(int idx) => setState(() => _selectedIndex = idx);

  // Language picker dialog (same as before, but with .tr())
  Future<void> _showLanguagePopup() => showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'language_selection'.tr(),
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('select_language'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  )),
              const SizedBox(height: 20),
              for (var code in ['en', 'hi', 'mr'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      widget.setLocale(Locale(code));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('lang_$code'.tr()),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) => ScaleTransition(
      scale: anim,
      child: child,
    ),
  );

  // Build the drawer, now with a Dark Mode toggle
  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 10),
                  Text('care_sync_user'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      )),
                  const SizedBox(height: 5),
                  Text('user_email'.tr(),
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.language,
                color: Theme.of(context).iconTheme.color),
            title: Text('change_language'.tr()),
            onTap: () {
              Navigator.pop(context);
              _showLanguagePopup();
            },
          ),
          ListTile(
            leading: Icon(Icons.brightness_6,
                color: Theme.of(context).iconTheme.color),
            title: Text('dark_mode'.tr()),
            trailing: Switch(
              value: isDark,
              onChanged: (on) {
                widget.setThemeMode(on ? ThemeMode.dark : ThemeMode.light);
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading:
            Icon(Icons.logout, color: Theme.of(context).iconTheme.color),
            title: Text('logout'.tr()),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build our screens list dynamically, so we can inject the two callbacks
    final screens = [
      const UploadReportScreen(),
      const ReminderScreen(),
      const ChatbotScreen(),
      const VoiceAssistantScreen(),
      ProfileScreen(
        setLocale: widget.setLocale,
        setThemeMode: widget.setThemeMode,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarKeys[_selectedIndex].tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        margin:
        const EdgeInsets.only(left: 10, right: 10, bottom: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            height: 70,
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor:
              Theme.of(context).bottomNavigationBarTheme.selectedItemColor ??
                  Colors.white,
              unselectedItemColor: Colors.white70,
              selectedFontSize: 14,
              unselectedFontSize: 14,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.file_upload),
                  label: 'upload'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.alarm),
                  label: 'reminders'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat),
                  label: 'chat'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.mic),
                  label: 'voice'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: 'profile'.tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
