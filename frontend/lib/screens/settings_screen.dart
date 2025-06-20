import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../../App/App/prescription_medical/lib/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final user = FirebaseAuth.instance.currentUser;
    // final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // TODO: Replace with user info from backend if needed
          // if (user != null) ...[
          //   ListTile(
          //     leading: CircleAvatar(
          //       backgroundImage: user.photoURL != null
          //           ? NetworkImage(user.photoURL!)
          //           : null,
          //       child: user.photoURL == null ? const Icon(Icons.person) : null,
          //     ),
          //     title: Text(user.displayName ?? 'User'),
          //     subtitle: Text(user.email ?? ''),
          //   ),
          //   const Divider(),
          // ],
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement notifications settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications settings coming soon!'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement theme settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme settings coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement language settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon!')),
              );
            },
          ),
          const Divider(),
          ListTile(
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
                        // TODO: Implement account deletion with backend
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
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // TODO: Implement sign out with backend
              // await authService.signOut();
              // if (context.mounted) {
              //   Navigator.of(context).pushReplacementNamed('/login');
              // }
            },
          ),
        ],
      ),
    );
  }
}
