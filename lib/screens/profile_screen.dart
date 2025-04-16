// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(Locale) setLocale;
  final void Function(ThemeMode) setThemeMode;

  const ProfileScreen({
    Key? key,
    required this.setLocale,
    required this.setThemeMode,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  late SharedPreferences _prefs;
  User? _user;
  String? _name;
  String? _phone;
  String? _avatarPath;
  bool _isAdmin = false;
  bool _darkMode = false;
  String _languageCode = 'en';

  final Map<String, String> _languages = {
    'en': 'English',
    'hi': 'Hindi',
    'mr': 'Marathi',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _prefs = await SharedPreferences.getInstance();
    _user = FirebaseAuth.instance.currentUser;

    setState(() {
      _name = _prefs.getString('profile_name') ?? _user?.displayName ?? '';
      _phone = _prefs.getString('profile_phone') ?? '';
      _avatarPath = _prefs.getString('profile_avatar');
      _isAdmin = _prefs.getBool('profile_isAdmin') ?? false;
      _darkMode = _prefs.getBool('profile_darkMode') ?? false;
      _languageCode = _prefs.getString('profile_lang') ?? 'en';
    });

    // Apply saved theme & locale on load
    widget.setThemeMode(_darkMode ? ThemeMode.dark : ThemeMode.light);
    widget.setLocale(Locale(_languageCode));
  }

  Future<void> _pickAvatar() async {
    final XFile? pic = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (pic != null) {
      await _prefs.setString('profile_avatar', pic.path);
      setState(() => _avatarPath = pic.path);
    }
  }

  Future<void> _editField(
      String title, String key, String? initial) async {
    final controller = TextEditingController(text: initial);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final val = controller.text.trim();
              await _prefs.setString(key, val);
              setState(() {
                if (key == 'profile_name') _name = val;
                if (key == 'profile_phone') _phone = val;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final email = _user?.email ?? '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset email to\n$email?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance
                  .sendPasswordResetEmail(email: email);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                  Text('Password reset link sent to your email.'),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDarkModeChanged(bool on) async {
    await _prefs.setBool('profile_darkMode', on);
    setState(() => _darkMode = on);
    widget.setThemeMode(on ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _onLanguageChanged(String code) async {
    await _prefs.setString('profile_lang', code);
    setState(() => _languageCode = code);
    widget.setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding:
          const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!))
                      : (_user?.photoURL != null
                      ? NetworkImage(_user!.photoURL!)
                      : const AssetImage(
                      'assets/images/avatar_placeholder.png')
                  as ImageProvider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoTile('Name', _name ?? '', Icons.person,
                            () => _editField(
                            'Name', 'profile_name', _name)),
                    const Divider(),
                    _buildInfoTile('Email', _user?.email ?? '',
                        Icons.email, null),
                    const Divider(),
                    _buildInfoTile('Phone', _phone ?? '',
                        Icons.phone, () => _editField(
                            'Phone', 'profile_phone', _phone)),
                    const Divider(),
                    _buildInfoTile('Role', _isAdmin ? 'Admin' : 'User',
                        Icons.shield, null),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      trailing: DropdownButton<String>(
                        value: _languageCode,
                        items: _languages.entries
                            .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                            .toList(),
                        onChanged: (v) => _onLanguageChanged(v!),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      secondary: const Icon(Icons.brightness_6),
                      title: const Text('Dark Mode'),
                      value: _darkMode,
                      onChanged: _onDarkModeChanged,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: const Text('Change Password'),
                      onTap: _changePassword,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isAdmin)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Go to Admin Panel'),
                onPressed: () => Navigator.pushNamed(context, '/admin'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon,
      VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(label),
      subtitle: Text(value),
      trailing: onTap != null
          ? const Icon(Icons.edit, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
