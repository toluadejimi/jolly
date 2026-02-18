// ignore: file_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/pref_data.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/widget_utils.dart';
import 'package:giftfr/constants/color_data.dart';
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
          backgroundColor: backgroundColor,
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      EdgeInsets.all(Constant.getPercentSize(iconSize, 25)),
                  child: getSvgImage("Bag.svg", iconSize, color: fontBlack)
                  // Image.asset(
                  //   Constant.assetImagePath + "logo_img.png",
                  //   width: iconSize,
                  //   height: iconSize,
                  //   fit: BoxFit.fill,
                  //   color: fontBlack,
                  // ),
                ),
                getCustomText("Gift Store", fontBlack, 1, TextAlign.center,
                    FontWeight.w900, Constant.getPercentSize(screenHeight, 5.5))
              ],
            ),
          ),
        ),
        onWillPop: () async {
          Constant.backToFinish(context);
          return false;
        });
  }
}
