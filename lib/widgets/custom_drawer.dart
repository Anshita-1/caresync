import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  final Function(Locale) setLocale;
  const CustomDrawer({Key? key, required this.setLocale}) : super(key: key);

  _logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("Super Duper Health App",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ExpansionTile(
              leading: Icon(Icons.language),
              title: Text("Change Language"),
              children: [
                ListTile(
                  title: Text("English"),
                  onTap: () {
                    setLocale(Locale('en'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text("Hindi"),
                  onTap: () {
                    setLocale(Locale('hi'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text("Marathi"),
                  onTap: () {
                    setLocale(Locale('mr'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () => _logout(context),
            ),
          ],
        ));
  }
}
