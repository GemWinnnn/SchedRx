import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle bodyStyle = const TextStyle(fontSize: 16);
    TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('Privacy Policy'),
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
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              RichText(
                text: TextSpan(
                  style: bodyStyle.copyWith(color: Colors.black),
                  children: [
                    TextSpan(text: '1. ', style: boldStyle),
                    TextSpan(text: 'Data Collection\n', style: boldStyle),
                    const TextSpan(
                      text:
                          'SchedRx collects limited personal information necessary to provide its core features. This includes your medication names, schedules, and notification preferences. No sensitive personal health data, such as diagnoses or prescriptions from doctors, is requested or required. Any information you manually input is stored securely in our database.\n\n',
                    ),
                    TextSpan(text: '2. ', style: boldStyle),
                    TextSpan(text: 'How We Use Your Data\n', style: boldStyle),
                    const TextSpan(
                      text:
                          'The data you provide is used solely for the purpose of scheduling reminders and improving your medication adherence. Notifications are generated locally on your device based on the schedule you input. We do not use your data for advertising, profiling, or any third-party analytics.\n\n',
                    ),
                    TextSpan(text: '3. ', style: boldStyle),
                    TextSpan(
                      text: 'Data Sharing and Third Parties\n',
                      style: boldStyle,
                    ),
                    const TextSpan(
                      text:
                          'We do not sell, share, or disclose your personal data to third parties. Your information remains private and accessible only to you. If cloud storage (e.g., Firebase) is used for backup, it adheres to industry-standard encryption and security practices.\n\n',
                    ),
                    TextSpan(text: '4. ', style: boldStyle),
                    TextSpan(
                      text: 'User Control and Consent\n',
                      style: boldStyle,
                    ),
                    const TextSpan(
                      text:
                          'You can manage, edit, or delete your medication schedules at any time within the app. Notification permissions can also be toggled in your device settings. By using the app, you consent to this privacy policy and the way your data is used as described.\n\n',
                    ),
                    TextSpan(text: '5. ', style: boldStyle),
                    TextSpan(
                      text: 'Updates to This Policy\n',
                      style: boldStyle,
                    ),
                    const TextSpan(
                      text:
                          'We may update this privacy policy from time to time to reflect changes in features or legal requirements. Any updates will be posted within the app. Continued use of the app after such changes implies your agreement with the revised policy.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
