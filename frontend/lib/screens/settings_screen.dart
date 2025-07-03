import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'noti_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = value;
    });
    await prefs.setBool('notificationsEnabled', value);

    if (value) {
      final snapshot = await FirebaseFirestore.instance
          .collection('medicines')
          .get();

      int notifId = 0;
      for (final doc in snapshot.docs) {
        final med = doc.data();
        final name = med['name'] ?? 'Medicine';
        final timesField = med['times'];
        List timesList = [];
        if (timesField is List) {
          timesList = timesField;
        } else if (timesField is Map) {
          timesList = timesField.values.toList();
        }

        for (final t in timesList) {
          TimeOfDay? timeOfDay;
          try {
            if (t is String) {
              final parts = t.split(':');
              if (parts.length == 2) {
                timeOfDay = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              }
            } else if (t is Timestamp) {
              final dt = t.toDate();
              timeOfDay = TimeOfDay(hour: dt.hour, minute: dt.minute);
            }
          } catch (_) {}

          timeOfDay ??= TimeOfDay.now();
          await NotiService.scheduleNotification(
            id: notifId++,
            title: 'Time to take your medicine',
            body: 'Take $name at ${timeOfDay.format(context)}',
            time: timeOfDay,
          );
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notifications enabled.')));
    } else {
      await NotiService.cancelAllNotifications();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notifications disabled.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings'),
        flexibleSpace: Container(
          alignment: Alignment.bottomCenter,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                ),
                Switch(
                  value: notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: Colors.white,
                  activeTrackColor: Color(0xFF34C759),
                  inactiveTrackColor: Color(0xFFDDDDDD),
                  inactiveThumbColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // About
          _settingsTile(
            context,
            icon: Icons.info_outline,
            label: 'About',
            route: '/about',
          ),

          // Privacy Policy
          _settingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            route: '/privacy',
          ),

          // Terms
          _settingsTile(
            context,
            icon: Icons.article_outlined,
            label: 'Terms',
            route: '/terms',
          ),

          const SizedBox(height: 12),

          // Delete Account
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text(
                      'Are you sure you want to delete your account? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account deletion coming soon!'),
                            ),
                          );
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 46, 46, 46)),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.normal),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.of(context).pushNamed(route),
      ),
    );
  }
}
