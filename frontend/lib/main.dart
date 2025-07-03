import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/add_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/terms_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/noti_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotiService.initialize();
  print('Firebase initialized!');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchedRx',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: Colors.white,
          primary: const Color.fromARGB(255, 0, 31, 45), // important
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const MainNavigation(),
      routes: {
        '/about': (context) => const AboutScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/terms': (context) => const TermsScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    CalendarScreen(),
    AddScreen(),
    ListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    NotiService.initialize();
    _scheduleAllMedicineNotifications();
  }

  Future<void> _scheduleAllMedicineNotifications() async {
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
        timeOfDay ??= TimeOfDay.now();
        await NotiService.scheduleNotification(
          id: notifId++,
          title: 'Time to take your medicine',
          body: 'Take $name at ${timeOfDay.format(context)}',
          time: timeOfDay,
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _screens[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Medicines'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF117CF5),
        unselectedItemColor: Color.fromARGB(255, 157, 157, 157),
        showUnselectedLabels: true,
      ),
    );
  }
}
