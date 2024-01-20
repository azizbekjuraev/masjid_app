import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';

class OnBoarding extends StatelessWidget {
  const OnBoarding({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnBoardingSlider(
        headerBackgroundColor: Colors.white,
        finishButtonText: 'Boshlash',
        finishButtonStyle: FinishButtonStyle(
          backgroundColor: AppStyles.backgroundColorGreen700,
        ),
        skipTextButton: const Text("O'tkazib yuborish"),
        trailing: const Text('Login'),
        background: [
          SizedBox(
            width: 400,
            height: 600,
            child: Image.asset(
              'assets/mosque.png',
            ),
          ),
          Image.asset('assets/logo.png'),
        ],
        totalPage: 2,
        speed: 1.8,
        pageBodies: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: const Column(
              children: <Widget>[
                SizedBox(
                  height: 500,
                ),
                Text("Hush kelibsiz"),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: const Column(
              children: <Widget>[
                SizedBox(
                  height: 480,
                ),
                Text('Description Text 2'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
