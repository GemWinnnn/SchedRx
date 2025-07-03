import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle bodyStyle = const TextStyle(fontSize: 16);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('About SchedRx'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          flexibleSpace: Container(
            alignment: Alignment.bottomCenter,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFCFCFC),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What is SchedRx?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'SchedRx is a mobile application designed to help you manage your medications more effectively. By setting daily reminders, you can ensure that no dose is missed and that your health routines stay consistent.',
                style: bodyStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'Our goal is to support users with a simple, secure, and user-friendly experience. Whether you’re tracking a single medication or multiple, SchedRx helps you stay on top of your routine.',
                style: bodyStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'SchedRx stores all reminders locally or in your secure cloud account, depending on your settings. Notifications are handled directly on your device to maintain privacy.',
                style: bodyStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'For questions, support, or suggestions, feel free to reach out to our development team through the app’s contact form or via email.',
                style: bodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
