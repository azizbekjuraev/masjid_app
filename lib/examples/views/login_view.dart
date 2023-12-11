import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

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

      print(email);

      if (email.isEmpty) {
        showAlertDialog(context, 'Xato', 'Elektron pochtangizni kiriting');
        return;
      } else if (password.isEmpty) {
        showAlertDialog(context, 'Xato', 'Parolingizni kiriting');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Close the dialog
      if (!context.mounted) return;
      Navigator.pop(context);

      UserData.setEmail(email).then((_) {
        // Access the logged-in user details
        User? user = userCredential.user;
        if (user?.email == email) {
          Navigator.pushNamed(context, './main/');
        }
      }).catchError((error) {
        showAlertDialog(context, 'Error setting email', '$error');
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showAlertDialog(context, 'Error', 'User not found!');
        return;
      } else if (e.code == 'wrong-password') {
        showAlertDialog(
            context, 'Error', 'Your password is incorrect, try again!');
        return;
      } else if (e.code == 'network-request-failed') {
        showAlertDialog(context, 'Network Request Failed.',
            'You do not have a proper network connection.');
        return;
      } else if (e.code == 'email-already-in-use') {
        showAlertDialog(context, "Error",
            'The email address is already in use by another account.');
        return;
      } else if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        showAlertDialog(context, "Error", "Register first, then log in!");
        return;
      }
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
                  PlatformTextButton(
                    onPressed: () async {
                      await _signInWithEmailAndPassword();
                    },
                    child: const Text('Kirish'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
