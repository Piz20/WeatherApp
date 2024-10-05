import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Google Sign-In instance
  final FirebaseAuth _auth = FirebaseAuth.instance;  // FirebaseAuth instance
  bool _isSigningIn = false;

  // Function to handle Google Sign-In with FirebaseAuth
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // If the user cancels the sign-in, return early
        setState(() {
          _isSigningIn = false;
        });
        return;
      }

      // Obtain the Google Auth credentials
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential using GoogleAuthProvider for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Retrieve the signed-in Firebase user
      final User? user = userCredential.user;

      if (user != null) {
        // User signed in successfully

        // Redirect to MapScreen after successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      }
    } catch (error) {
    } finally {
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Couleur d'arrière-plan adaptative
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centre le contenu (logo et bouton)
                children: <Widget>[
                  // Logo of the app
                  Image.asset(
                    'assets/logos/logo.png', // Add your logo image here
                    height: MediaQuery.of(context).size.height * 0.3, // 30% de la hauteur de l'écran
                  ),
                  const SizedBox(height: 50),

                  // Stack to show button and CircularProgressIndicator
                  Stack(
                    alignment: Alignment.center, // Center the progress indicator
                    children: [
                      // Google Sign-In button
                      ElevatedButton(
                        onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50), // Full-width button
                        ),
                        child: Offstage(
                          offstage: _isSigningIn, // Masquer le contenu si _isSigningIn est vrai
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/logos/google_logo.png', // Assurez-vous que le chemin vers l'icône de Google est correct
                                height: 24, // Taille de l'icône
                                width: 24,
                              ),
                              const SizedBox(width: 8), // Espace entre l'icône et le texte
                              const Text(
                                'Sign in with Google', // Texte en anglais
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // CircularProgressIndicator
                      if (_isSigningIn) // Show progress indicator only when signing in
                        const CircularProgressIndicator(),
                    ],
                  ),
                ],
              ),
            ),

            // Copyright section
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '© Laforge, Tous droits réservés', // Message de copyright
                  style: TextStyle(
                    color: Colors.grey, // Couleur du texte
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Espace entre le texte de copyright et le bas de l'écran
          ],
        ),
      ),
    );
  }

}
