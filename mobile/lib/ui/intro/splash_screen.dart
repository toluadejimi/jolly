// ignore: file_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/pref_data.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:giftfr/ui/intro/intro_screen.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SplashScreen();
  }
}

class _SplashScreen extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 2),
      () async {
        if (!mounted) return;
        final showIntro = await PrefData.isIntroAvailable();
        final isLoggedIn = await PrefData.isLogIn();
        if (!mounted) return;
        if (showIntro) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const IntroScreen()),
          );
        } else if (isLoggedIn) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;

    double iconSize = Constant.getPercentSize(screenHeight, 10);

    return WillPopScope(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: Constant.getPercentSize(screenHeight, 8)),
                child: Image.asset(
                  Constant.assetImagePath + "jellyboxfr_logo.png",
                  width: iconSize * 2.2,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        onWillPop: () async {
          Constant.backToFinish(context);
          return false;
        });
  }
}
