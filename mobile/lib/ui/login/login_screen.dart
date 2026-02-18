// ignore: file_names
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/widget_utils.dart';
import 'package:giftfr/providers/auth_provider.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:giftfr/ui/login/forgot_password_screen.dart';

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
          body: getBackgroundWidget(
            Column(
              mainAxisSize: MainAxisSize.min,
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
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: Constant.getPercentSize(screenWidth, 5)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          getSpace(Constant.getPercentSize(screenHeight, 2.5)),
                          _buildProfessionalField(
                            context: context,
                            controller: emailSignInController,
                            hint: 'Email or username',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 1.8)),
                          _buildProfessionalPasswordField(
                            context: context,
                            controller: passSignInController,
                            hint: 'Password',
                            obscure: !isShowPass.value,
                            onToggle: () => setState(() => isShowPass.value = !isShowPass.value),
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 1)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  Constant.sendToScreen(const ForgotPasswordScreen(), context),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 2)),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      final username = emailSignInController.text.trim();
                                      final password = passSignInController.text;
                                      if (username.isEmpty || password.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Please enter email and password')),
                                        );
                                        return;
                                      }
                                      setState(() => _isLoading = true);
                                      final api = context.read<ApiService>();
                                      final auth = context.read<AuthProvider>();
                                      final result =
                                          await api.login(username: username, password: password);
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
                                            MaterialPageRoute(
                                                builder: (context) => HomeScreen()));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    result.error ?? 'Login failed')));
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(_isLoading ? 'Signing in…' : 'Sign In',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 16)),
                            ),
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 1.5)),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => HomeScreen()));
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Continue as guest',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: Constant.getPercentSize(screenWidth, 5)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          getSpace(Constant.getPercentSize(screenHeight, 2)),
                          _buildProfessionalField(
                            context: context,
                            controller: firstnameController,
                            hint: 'First name',
                            textCapitalization: TextCapitalization.words,
                            prefixIcon: Icons.person_outline,
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 1.8)),
                          _buildProfessionalField(
                            context: context,
                            controller: lastnameController,
                            hint: 'Last name',
                            textCapitalization: TextCapitalization.words,
                            prefixIcon: Icons.person_outline,
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 1.8)),
                          _buildProfessionalField(
                            context: context,
                            controller: emailRegPhoneController,
                            hint: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 1.8)),
                          _buildProfessionalPasswordField(
                            context: context,
                            controller: passSignInController,
                            hint: 'Password',
                            obscure: !isShowPass.value,
                            onToggle: () => setState(() => isShowPass.value = !isShowPass.value),
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 1.8)),
                          _buildProfessionalPasswordField(
                            context: context,
                            controller: confirmPassController,
                            hint: 'Confirm password',
                            obscure: !isShowConfirmPass.value,
                            onToggle: () => setState(() => isShowConfirmPass.value = !isShowConfirmPass.value),
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 2)),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
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
                                  },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                _isLoading ? 'Registering…' : 'Register',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                          ),
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
          ),
            title: '',
            headerColor: lightOrangeHeader,
          ),
        ),
        onWillPop: () async {
          Constant.closeApp();
          return false;
        });
  }

  Widget _buildProfessionalField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    IconData prefixIcon = Icons.edit_outlined,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyle(
        fontSize: 16,
        color: fontBlack,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: greyFont.withOpacity(0.8),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 22,
          color: primaryColor.withOpacity(0.8),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildProfessionalPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        fontSize: 16,
        color: fontBlack,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: greyFont.withOpacity(0.8),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          size: 22,
          color: primaryColor.withOpacity(0.8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 22,
            color: greyFont,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

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
