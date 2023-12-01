import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    try {
      final String email = _email.text.trim();
      final String password = _password.text;

      if (email.isEmpty || password.isEmpty) {
        // Show an error message, e.g., using a function to display an alert
        // showErrorDialog(context, 'Email and password are required.');
        return;
      }

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Access the logged-in user details
      User? user = userCredential.user;
      print(user?.email == email);
      if (user?.email == email) {
        Navigator.pushNamed(context, './main/');
      }

      // Now you can navigate to the next screen or perform other actions
      // For example, you can use Navigator.pushReplacement() to replace the login screen
      // with the home screen.

      print('User logged in: ${user?.uid}');
    } catch (e) {
      print('Error signing in: $e');
      // Show an error message, e.g., using a function to display an alert
      // showErrorDialog(context, 'Failed to sign in. Check your email and password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const height = SizedBox(
      height: 20,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tizimga kirish',
                style: TextStyle(fontSize: 30),
              ),
              height,
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Elektron pochta',
                ),
                keyboardType: TextInputType.emailAddress,
                controller: _email,
                enableSuggestions: false,
                autocorrect: false,
              ),
              height,
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Parol',
                ),
                controller: _password,
                enableSuggestions: false,
                autocorrect: false,
                obscureText: true,
              ),
              height,
              Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      await _signInWithEmailAndPassword();
                    },
                    child: const Text('Kirish'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to the registration screen
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationView()));
                    },
                    child: const Text('Not registered yet? Register here!'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
