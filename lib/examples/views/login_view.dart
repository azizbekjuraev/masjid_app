import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:masjid_app/examples/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool isLoading = false;

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
      setState(() {
        isLoading = true;
      });

      final String email = _email.text.trim();
      final String password = _password.text;

      if (email.isEmpty) {
        showAlertDialog(context, 'Elektron pochtangizni kiriting...',
            toastType: ToastificationType.warning);
        return;
      } else if (password.isEmpty) {
        showAlertDialog(context, 'Parolingizni kiriting....',
            toastType: ToastificationType.warning);
        return;
      }
      // Move the actual sign-in code inside the try block
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the current user in the provider
      Provider.of<CurrentUserProvider>(context, listen: false)
          .setCurrentUser(userCredential.user);

      // on success
      if (!context.mounted) return;
      showAlertDialog(
          context,
          title: "Xush kelibsiz!",
          "Tizimga admin bo'lib kirdingiz...",
          toastType: ToastificationType.success,
          toastAlignment: Alignment.bottomCenter,
          margin: const EdgeInsets.only(bottom: 35.0));

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuthExceptions
      if (e.code == 'too-many-requests') {
        if (!context.mounted) return;
        showAlertDialog(
          context,
          "Juda koʻp so'rovlar yubordingiz, parolni tekshirib, qaytadan urinib ko'ring...",
        );
      }
      if (e.code == 'invalid-email') {
        if (!context.mounted) return;
        showAlertDialog(
          context,
          "Iltimos, elektron pochtani to'g'ri to'ldiring...",
        );
      }
      if (e.code == 'invalid-credential') {
        if (!context.mounted) return;
        showAlertDialog(
          context,
          "Parolni to'g'ri to'ldiring...",
        );
      }
      if (e.code == 'user-not-found') {
        if (!context.mounted) return;
        showAlertDialog(context, 'Foydalanuvchi topilmadi...');
      } else if (e.code == 'wrong-password') {
        if (!context.mounted) return;
        showAlertDialog(
          context,
          "Parolingiz noto'g'ri, qayta urinib ko'ring...",
        );
      } else if (e.code == 'network-request-failed') {
        if (!context.mounted) return;
        showAlertDialog(
          context,
          "Sizda to'g'ri tarmoq ulanishi yo'q...",
        );
      } else if (e.code == 'email-already-in-use') {
        if (!context.mounted) return;
        showAlertDialog(
          context,
          'Bu E-pochta manzili allaqachon boshqa hisobda ishlatilmoqda...',
        );
      } else if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        if (!context.mounted) return;
        showAlertDialog(
            context, "Elektron pochta yoki parol noto'g'ri kiritildi...");
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const height = SizedBox(
      height: 20,
    );
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(child: Text('Masjidlar Takbir Vaqtlari')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: SingleChildScrollView(
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
                        FocusScope.of(context).unfocus();
                        await _signInWithEmailAndPassword();
                      },
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Kirish'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
