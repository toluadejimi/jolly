// ignore: file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/constant.dart';

import '../../constants/size_config.dart';
import '../../constants/widget_utils.dart';
import '../../constants/color_data.dart';
import '../../services/api_service.dart';
import 'reset_password_dialog_box.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChangePasswordScreen();
  }
}

class _ChangePasswordScreen extends State<ChangePasswordScreen> {
  void backScreen() {
    Constant.backToFinish(context);
  }

  FocusNode focusNode = FocusNode();
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  ValueNotifier<bool> showCurrentPass = ValueNotifier(false);
  ValueNotifier<bool> showNewPass = ValueNotifier(false);
  ValueNotifier<bool> showConfirmPass = ValueNotifier(false);
  bool _loading = false;

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final current = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;
    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your current password')),
      );
      return;
    }
    if (newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter new password')),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm do not match')),
      );
      return;
    }
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    final res = await api.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      showDialog(
        context: context,
        builder: (ctx) => ResetPasswordDialogBox(
          func: () {
            Navigator.pop(ctx);
            backScreen();
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to change password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double appBarPadding = getAppBarPadding();

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: getBackgroundWidget(
          Container(
            padding: EdgeInsets.all(appBarPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: backScreen,
                      child: Icon(
                        Icons.keyboard_backspace_rounded,
                        size: getEdtIconSize(),
                        color: fontBlack,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    getCustomText(
                      "Change Password",
                      fontBlack,
                      1,
                      TextAlign.center,
                      FontWeight.w800,
                      getLoginTitleFontSize(),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                getSpace(appBarPadding),
                getCustomTextWithoutMaxLine(
                  "Enter your current password and choose a new password.",
                  fontBlack,
                  TextAlign.center,
                  FontWeight.w400,
                  getEdtTextSize(),
                ),
                getSpace(appBarPadding),
                ValueListenableBuilder(
                  builder: (context, value, child) {
                    return getPassTextField(
                      currentPasswordController,
                      "Current password",
                      "eye.svg",
                      showCurrentPass.value,
                      () => showCurrentPass.value = !showCurrentPass.value,
                    );
                  },
                  valueListenable: showCurrentPass,
                ),
                ValueListenableBuilder(
                  builder: (context, value, child) {
                    return getPassTextField(
                      newPasswordController,
                      "New password",
                      "eye.svg",
                      showNewPass.value,
                      () => showNewPass.value = !showNewPass.value,
                    );
                  },
                  valueListenable: showNewPass,
                ),
                ValueListenableBuilder(
                  builder: (context, value, child) {
                    return getPassTextField(
                      confirmPasswordController,
                      "Confirm new password",
                      "eye.svg",
                      showConfirmPass.value,
                      () => showConfirmPass.value = !showConfirmPass.value,
                    );
                  },
                  valueListenable: showConfirmPass,
                ),
                getSpace(appBarPadding),
                getButton(
                  primaryColor,
                  !_loading,
                  _loading ? "Updating…" : "Submit",
                  Colors.white,
                  _submit,
                  FontWeight.w600,
                  EdgeInsets.symmetric(vertical: appBarPadding),
                ),
              ],
            ),
          ),
          title: 'Change password',
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
      focusNode.dispose();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    super.dispose();
  }
}
