import 'package:flutter/material.dart';

class DeveloperInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Developers & App Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Developer Information
            Text(
              'Developers:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Piz',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '• Darrel',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Purpose of the App
            Text(
              'This app was developed as part of the NASA Space Apps Challenge. The main objective of the app is to provide critical climate and natural disaster information such as temperature, flood risks, and other environmental hazards for specific regions. The data helps users make informed decisions and stay safe in case of natural disasters.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // NASA Space Apps Challenge
            Text(
              'About NASA Space Apps Challenge:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'NASA Space Apps Challenge is an international hackathon that encourages innovative solutions to real-world problems faced by Earth and space sciences using open data provided by NASA.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Additional credits or acknowledgment (if necessary)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Return to the previous page
                },
                child: const Text('Back' , style: TextStyle(color: Colors.blue),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
