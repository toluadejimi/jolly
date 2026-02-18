// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/color_data.dart';

import '../../constants/constant.dart';
import '../../constants/widget_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, this.initialTab = 0}) : super(key: key);
  final int initialTab;

  @override
  State<StatefulWidget> createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedTabbar;
  TextEditingController emailRegPhoneController = TextEditingController();
  TextEditingController emailSignInController = TextEditingController();
  TextEditingController passSignInController = TextEditingController();
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  ValueNotifier<bool> isShowPass = ValueNotifier(false);
  ValueNotifier<bool> isShowConfirmPass = ValueNotifier(false);
  bool chkVal = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTabbar = widget.initialTab;
    _tabController = TabController(vsync: this, length: 2, initialIndex: widget.initialTab);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double appbarPadding = getAppBarPadding();
    return WillPopScope(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: getBackgroundWidget(Column(
            children: [
              TabBar(
                onTap: (value) {
                  _selectedTabbar = value;
                  setState(() {});
                },
                tabs: [
                  Tab(
                      child: Text(
                    "Sign in",
                    style: TextStyle(
                      decoration: (_selectedTabbar == 0)
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: primaryColor.withOpacity(0.4),
                      decorationThickness: 6,
                      decorationStyle: TextDecorationStyle.solid,
                    ),
                  )),
                  Tab(
                      child: Text(
                    "Register",
                    style: TextStyle(
                      decoration: (_selectedTabbar == 1)
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: primaryColor.withOpacity(0.4),
                      decorationThickness: 6,
                      decorationStyle: TextDecorationStyle.solid,
                    ),
                  ))
                ],
                unselectedLabelColor: Colors.grey,
                labelColor: fontBlack,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 0,
                indicatorPadding: EdgeInsets.zero,
                // indicatorSize: TabBarIndicatorSize.label,
                labelPadding: EdgeInsets.zero,
                indicatorColor: primaryColor,
                indicator: const UnderlineTabIndicator(
                  insets: EdgeInsets.all(0),
                ),
                padding: EdgeInsets.zero,
                labelStyle: TextStyle(
                    color: fontBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: Constant.getPercentSize(screenHeight, 3)),
                controller: _tabController,
                isScrollable: false,
              ),
              (_selectedTabbar == 0)
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: Constant.getPercentSize(screenWidth, 4)),
                      child: Column(
                        children: [
                          getSpace(Constant.getPercentSize(screenHeight, 3)),
                          getLoginTextField(
                              emailSignInController, "Email", "email.svg"),
                          ValueListenableBuilder(
                            builder: (context, value, child) {
                              return getPassTextField(passSignInController,
                                  "Password", "eye.svg", isShowPass.value, () {
                                isShowPass.value = !isShowPass.value;
                              });
                            },
                            valueListenable: isShowPass,
                          ),
                          Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  Constant.sendToScreen(
                                      const ForgotPasswordScreen(), context);
                                },
                                child: getCustomText(
                                    "Forgot Password?",
                                    fontBlack,
                                    1,
                                    TextAlign.end,
                                    FontWeight.bold,
                                    Constant.getPercentSize(screenHeight, 2.3)),
                              )),
                          getSpace(appbarPadding / 2),
                          getButton(primaryColor, true, _isLoading ? "Signing in…" : "Sign In", Colors.white,
                              () async {
                            final username = emailSignInController.text.trim();
                            final password = passSignInController.text;
                            if (username.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter email and password')),
                              );
                              return;
                            }
                            setState(() => _isLoading = true);
                            final api = context.read<ApiService>();
                            final auth = context.read<AuthProvider>();
                            final result = await api.login(username: username, password: password);
                            if (!mounted) return;
                            setState(() => _isLoading = false);
                            if (result.success && result.data != null) {
                              await auth.setFromLogin(
                                apiKey: result.data!.apiKey,
                                email: result.data!.user.email,
                                name: result.data!.user.displayName,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => HomeScreen()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.error ?? 'Login failed')),
                              );
                            }
                          }, FontWeight.w500,
                              EdgeInsets.symmetric(vertical: appbarPadding)),
                          getCustomText(
                              "Or sign in with",
                              Colors.grey,
                              1,
                              TextAlign.center,
                              FontWeight.w400,
                              Constant.getPercentSize(screenHeight, 2.2)),
                          Row(
                            children: [
                              Expanded(
                                child: getButtonContainer(
                                    Row(
                                      children: [
                                        getSvgImage(
                                            "email.svg", getEdtIconSize()),
                                        getHorSpace(Constant.getPercentSize(
                                            screenWidth, 1.7)),
                                        getCustomText(
                                            "Google",
                                            fontBlack,
                                            1,
                                            TextAlign.center,
                                            FontWeight.bold,
                                            getEdtTextSize())
                                      ],
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                    ),
                                    EdgeInsets.only(
                                        left: 0,
                                        top: appbarPadding,
                                        bottom: appbarPadding,
                                        right: appbarPadding / 2),
                                    backgroundColor),
                                flex: 1,
                              ),
                              Expanded(
                                child: getButtonContainer(
                                    Row(
                                      children: [
                                        getSvgImage(
                                            "facebook.svg", getEdtIconSize()),
                                        getHorSpace(Constant.getPercentSize(
                                            screenWidth, 1.7)),
                                        getCustomText(
                                            "Facebook",
                                            fontBlack,
                                            1,
                                            TextAlign.center,
                                            FontWeight.bold,
                                            getEdtTextSize())
                                      ],
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                    ),
                                    EdgeInsets.only(
                                        left: appbarPadding / 2,
                                        top: appbarPadding,
                                        bottom: appbarPadding,
                                        right: 0),
                                    backgroundColor),
                                flex: 1,
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: Constant.getPercentSize(screenWidth, 4)),
                      child: Column(
                        children: [
                          getSpace(Constant.getPercentSize(screenHeight, 2)),
                          getLoginTextField(
                              firstnameController, "First name", "email.svg"),
                          getLoginTextField(
                              lastnameController, "Last name", "email.svg"),
                          getLoginTextField(
                              emailRegPhoneController, "Email", "email.svg"),
                          ValueListenableBuilder(
                            builder: (context, value, child) {
                              return getPassTextField(passSignInController,
                                  "Password", "eye.svg", isShowPass.value, () {
                                isShowPass.value = !isShowPass.value;
                              });
                            },
                            valueListenable: isShowPass,
                          ),
                          ValueListenableBuilder(
                            builder: (context, value, child) {
                              return getPassTextField(confirmPassController,
                                  "Confirm password", "eye.svg", isShowConfirmPass.value, () {
                                isShowConfirmPass.value = !isShowConfirmPass.value;
                              });
                            },
                            valueListenable: isShowConfirmPass,
                          ),
                          getSpace(appbarPadding / 2),
                          getButton(
                              primaryColor, true, _isLoading ? "Registering…" : "Register", Colors.white, () async {
                            final email = emailRegPhoneController.text.trim();
                            final password = passSignInController.text;
                            final confirm = confirmPassController.text;
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter email')),
                              );
                              return;
                            }
                            if (password.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password must be at least 6 characters')),
                              );
                              return;
                            }
                            if (password != confirm) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Passwords do not match')),
                              );
                              return;
                            }
                            setState(() => _isLoading = true);
                            final api = context.read<ApiService>();
                            final auth = context.read<AuthProvider>();
                            final result = await api.register(
                              email: email,
                              password: password,
                              passwordConfirmation: confirm,
                              firstname: firstnameController.text.trim().isEmpty ? null : firstnameController.text.trim(),
                              lastname: lastnameController.text.trim().isEmpty ? null : lastnameController.text.trim(),
                            );
                            if (!mounted) return;
                            setState(() => _isLoading = false);
                            if (result.success && result.data != null) {
                              await auth.setFromLogin(
                                apiKey: result.data!.apiKey,
                                email: result.data!.user.email,
                                name: result.data!.user.displayName,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => HomeScreen()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.error ?? 'Registration failed')),
                              );
                            }
                          }, FontWeight.w500,
                              EdgeInsets.symmetric(vertical: appbarPadding)),
                        ],
                      ),
                    ),
              // TabBarView(
              //   children: [
              //     Container(
              //       width: double.infinity,
              //       padding: EdgeInsets.symmetric(
              //           horizontal: Constant.getPercentSize(
              //               screenWidth, 4)),
              //       child: Column(
              //         children: [
              //           getSpace(Constant.getPercentSize(
              //               screenHeight, 5)),
              //           getLoginTextField(emailSignInController,
              //               "Email", "eye.svg"),
              //           getPassTextField(passSignInController,
              //               "Password", "eye.svg", false),
              //         ],
              //       ),
              //     ),
              //     // Text("etetetet", style: TextStyle(color: Colors.black87)),
              //     Text("5758689789")
              //   ],
              //   controller: _tabController,
              // ),
            ],
          )),
        ),
        onWillPop: () async {
          Constant.closeApp();
          return false;
        });

    // return WillPopScope(
    //     child: Scaffold(
    //       backgroundColor: backgroundColor,
    //       body: Container(
    //         width: double.infinity,
    //         height: double.infinity,
    //         child: Stack(
    //           children: [
    //             Container(
    //               width: double.infinity,
    //               height: getTopViewHeight(),
    //               padding: EdgeInsets.only(bottom: getTopViewHeight() / 4),
    //               decoration: ShapeDecoration(
    //                   color: primaryColor,
    //                   shape: SmoothRectangleBorder(
    //                       borderRadius: SmoothBorderRadius.only(
    //                           bottomLeft: SmoothRadius(
    //                               cornerRadius: size, cornerSmoothing: 0.8),
    //                           bottomRight: SmoothRadius(
    //                               cornerRadius: size, cornerSmoothing: 0.8)))),
    //               child: Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 crossAxisAlignment: CrossAxisAlignment.center,
    //                 children: [
    //                   Image.asset(
    //                     Constant.assetImagePath + "logo_img.png",
    //                     height: imgSize,
    //                     width: imgSize,
    //                   ),
    //                   getHorSpace(Constant.getPercentSize(screenWidth, 3)),
    //                   getCustomText(
    //                       "Shopping",
    //                       Colors.white,
    //                       1,
    //                       TextAlign.start,
    //                       FontWeight.bold,
    //                       Constant.getPercentSize(imgSize, 65))
    //                 ],
    //               ),
    //             ),
    //             Container(
    //               width: double.infinity,
    //               height: double.infinity,
    //               child: Column(
    //                 children: [
    //                   getSpace(topHeight),
    //                   Expanded(
    //                     child: SingleChildScrollView(
    //                       child: Container(
    //                         width: double.infinity,
    //                         decoration: ShapeDecoration(
    //                             color: Colors.white,
    //                             shadows: [
    //                               BoxShadow(
    //                                   blurRadius: 3,
    //                                   color: Colors.black.withAlpha(20))
    //                             ],
    //                             shape: SmoothRectangleBorder(
    //                                 borderRadius: SmoothBorderRadius.all(
    //                                     SmoothRadius(
    //                                         cornerSmoothing: 0.5,
    //                                         cornerRadius:
    //                                             Constant.getPercentSize(
    //                                                 getRemainSize, 4))))),
    //                         margin: EdgeInsets.only(
    //                             // top: topHeight,
    //                             left: size / 2.2,
    //                             right: size / 2.2,
    //                             bottom: Constant.getPercentSize(
    //                                 getTopViewHeight(), 10)),
    //                         child: Column(
    //                           children: [
    //                             TabBar(
    //                               onTap: (value) {
    //                                 _selectedTabbar = value;
    //                                 setState(() {});
    //                               },
    //                               tabs: [
    //                                 Tab(
    //                                     child: Text(
    //                                   "Sign in",
    //                                   style: TextStyle(
    //                                     decoration: (_selectedTabbar == 0)
    //                                         ? TextDecoration.underline
    //                                         : TextDecoration.none,
    //                                     decorationColor:
    //                                         primaryColor.withOpacity(0.4),
    //                                     decorationThickness: 6,
    //                                     decorationStyle:
    //                                         TextDecorationStyle.solid,
    //                                   ),
    //                                 )),
    //                                 Tab(
    //                                     child: Text(
    //                                   "Register",
    //                                   style: TextStyle(
    //                                     decoration: (_selectedTabbar == 1)
    //                                         ? TextDecoration.underline
    //                                         : TextDecoration.none,
    //                                     decorationColor:
    //                                         primaryColor.withOpacity(0.4),
    //                                     decorationThickness: 6,
    //                                     decorationStyle:
    //                                         TextDecorationStyle.solid,
    //                                   ),
    //                                 ))
    //                               ],
    //                               unselectedLabelColor: Colors.grey,
    //                               labelColor: fontBlack,
    //                               indicatorSize: TabBarIndicatorSize.tab,
    //                               indicatorWeight: 0,
    //                               indicatorPadding: EdgeInsets.zero,
    //                               // indicatorSize: TabBarIndicatorSize.label,
    //                               labelPadding: EdgeInsets.zero,
    //                               indicatorColor: primaryColor,
    //                               indicator: UnderlineTabIndicator(
    //                                 insets: EdgeInsets.all(0),
    //                               ),
    //                               padding: EdgeInsets.zero,
    //                               labelStyle: TextStyle(
    //                                   color: fontBlack,
    //                                   fontWeight: FontWeight.bold,
    //                                   fontSize: Constant.getPercentSize(
    //                                       screenHeight, 3)),
    //                               controller: _tabController,
    //                               isScrollable: false,
    //                             ),
    //                             (_selectedTabbar == 0)
    //                                 ? Container(
    //                                     width: double.infinity,
    //                                     padding: EdgeInsets.symmetric(
    //                                         horizontal: Constant.getPercentSize(
    //                                             screenWidth, 4)),
    //                                     child: Column(
    //                                       children: [
    //                                         getSpace(Constant.getPercentSize(
    //                                             screenHeight, 5)),
    //                                         getLoginTextField(
    //                                             emailSignInController,
    //                                             "Email",
    //                                             "email.svg"),
    //                                         ValueListenableBuilder(
    //                                           builder: (context, value, child) {
    //                                             return getPassTextField(
    //                                                 passSignInController,
    //                                                 "Password",
    //                                                 "eye.svg",
    //                                                 isShowPass.value, () {
    //                                               isShowPass.value =
    //                                                   !isShowPass.value;
    //                                             });
    //                                           },
    //                                           valueListenable: isShowPass,
    //                                         ),
    //                                         Align(
    //                                           alignment: Alignment.centerRight,
    //                                           child: getCustomText(
    //                                               "Forgot Password?",
    //                                               fontBlack,
    //                                               1,
    //                                               TextAlign.end,
    //                                               FontWeight.bold,
    //                                               Constant.getPercentSize(
    //                                                   screenHeight, 2.3))
    //                                         ),
    //                                         getSpace(appba)
    //                                       ],
    //                                     ),
    //                                   )
    //                                 : Text("we4et4645654654"),
    //                             // TabBarView(
    //                             //   children: [
    //                             //     Container(
    //                             //       width: double.infinity,
    //                             //       padding: EdgeInsets.symmetric(
    //                             //           horizontal: Constant.getPercentSize(
    //                             //               screenWidth, 4)),
    //                             //       child: Column(
    //                             //         children: [
    //                             //           getSpace(Constant.getPercentSize(
    //                             //               screenHeight, 5)),
    //                             //           getLoginTextField(emailSignInController,
    //                             //               "Email", "eye.svg"),
    //                             //           getPassTextField(passSignInController,
    //                             //               "Password", "eye.svg", false),
    //                             //         ],
    //                             //       ),
    //                             //     ),
    //                             //     // Text("etetetet", style: TextStyle(color: Colors.black87)),
    //                             //     Text("5758689789")
    //                             //   ],
    //                             //   controller: _tabController,
    //                             // ),
    //                           ],
    //                         ),
    //                       ),
    //                     ),
    //                     flex: 1,
    //                   )
    //                 ],
    //               ),
    //             )
    //           ],
    //         ),
    //       ),
    //     ),
    //     onWillPop: () async {
    //       return false;
    //     });
  }
}
