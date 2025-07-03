import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle bodyStyle = const TextStyle(fontSize: 16);
    TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('Terms of Use'),
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
          child: RichText(
            text: TextSpan(
              style: bodyStyle.copyWith(color: Colors.black),
              children: const [
                TextSpan(
                  text: '1. Use of the App\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'SchedRx is provided for personal, non-commercial use only. Users are responsible for any data entered and must ensure it is accurate and up to date.\n\n',
                ),
                TextSpan(
                  text: '2. User Responsibilities\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'You are responsible for ensuring that your medication reminders are correctly scheduled. SchedRx is not a substitute for medical advice, diagnosis, or treatment.\n\n',
                ),
                TextSpan(
                  text: '3. Limitation of Liability\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'SchedRx is provided "as is" without any warranties. We are not liable for missed doses, health consequences, or errors in reminder scheduling.\n\n',
                ),
                TextSpan(
                  text: '4. Account Termination\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'We reserve the right to terminate access to users who misuse the app, breach terms, or compromise data security.\n\n',
                ),
                TextSpan(
                  text: '5. Updates\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'These terms may be updated at any time. Changes will be posted within the app. Continued use of the app after changes implies acceptance.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
