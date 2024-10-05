import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assuming Firebase is used for authentication

class UserInfoPage extends StatelessWidget {
  final User? user =
      FirebaseAuth.instance.currentUser;

   UserInfoPage({super.key}); // Get the currently logged-in user

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Sign out the user
    Navigator.pop(context); // Return to the previous page after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile picture or default icon
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            // User name
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Email address
            Text(
              user?.email ?? 'No email available',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Logout button
            ElevatedButton.icon(
              onPressed: () => _logout(context), // Call logout function
              icon: const Icon(Icons.exit_to_app, color: Colors.blue),
              label: const Text('Logout', style: TextStyle(color: Colors.blue)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.transparent,
                // Make button background transparent
                side: const BorderSide(color: Colors.blue), // Add border color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
