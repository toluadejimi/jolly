// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/providers/theme_provider.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:giftfr/ui/login/login_screen.dart';
import 'package:giftfr/screens/track_order_screen.dart';
import 'package:giftfr/screens/orders_list_screen.dart';
import 'package:giftfr/screens/track_order_screen.dart';
import 'package:giftfr/ui/login/change_password_screen.dart';
import 'package:giftfr/screens/profile_screen.dart';
import 'package:provider/provider.dart';

import '../../../constants/constant.dart';
import '../../../constants/pref_data.dart';
import '../../../constants/widget_utils.dart';
import '../../../providers/auth_provider.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> {
  Future<void> _refreshAuth() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double appBarPadding = getAppBarPadding();
    double imgHeight = Constant.getPercentSize(screenHeight, 16);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          getDefaultHeader(context, "Profile", () {}, (value) {},
              withFilter: false, isShowBack: false, isShowSearch: false),
          getSpace(appBarPadding),
          Expanded(
            child: FutureBuilder<bool>(
              future: PrefData.isLogIn(),
              builder: (context, snap) {
                final isLoggedIn = snap.data ?? false;
                if (!isLoggedIn) {
                  return _buildLoggedOutContent(context, theme, screenHeight, appBarPadding);
                }
                return _buildLoggedInContent(context, theme, screenHeight, appBarPadding, imgHeight);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutContent(BuildContext context, ThemeData theme, double screenHeight, double appBarPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(appBarPadding),
      child: Column(
        children: [
          getSpace(Constant.getPercentSize(screenHeight, 4)),
          Icon(Icons.person_outline, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          getSpace(appBarPadding),
          getCustomText(
            "You are not logged in",
            theme.colorScheme.onSurface,
            1,
            TextAlign.center,
            FontWeight.w600,
            Constant.getPercentSize(screenHeight, 2.5),
          ),
          getSpace(Constant.getPercentSize(appBarPadding, 50)),
          getCustomText(
            "Log in to view your profile, orders, and more.",
            theme.colorScheme.onSurfaceVariant,
            1,
            TextAlign.center,
            FontWeight.w400,
            Constant.getPercentSize(screenHeight, 2),
          ),
          getSpace(Constant.getPercentSize(screenHeight, 4)),
          getButton(
            theme.colorScheme.primary,
            true,
            "Log in",
            theme.colorScheme.onPrimary,
            () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              _refreshAuth();
            },
            FontWeight.w700,
            EdgeInsets.symmetric(horizontal: appBarPadding * 2, vertical: appBarPadding),
          ),
          getSpace(appBarPadding),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrackOrderScreen()),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Track order (no login required)'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent(
    BuildContext context,
    ThemeData theme,
    double screenHeight,
    double appBarPadding,
    double imgHeight,
  ) {
    return FutureBuilder<Map<String, String?>>(
      future: Future.wait([PrefData.getUserName(), PrefData.getUserEmail()]).then((l) => {'name': l[0], 'email': l[1]}),
      builder: (context, snap) {
        final name = snap.data?['name'] ?? '';
        final email = snap.data?['email'] ?? '';
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: appBarPadding * 2),
          child: Column(
            children: [
              Container(
                width: imgHeight,
                height: imgHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  image: DecorationImage(
                    image: AssetImage(Constant.assetImagePath + "banner.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              getSpace(appBarPadding),
              getCustomText(
                name.isNotEmpty ? name : "Account",
                theme.colorScheme.onSurface,
                1,
                TextAlign.center,
                FontWeight.bold,
                Constant.getPercentSize(screenHeight, 2.7),
              ),
              getSpace(Constant.getPercentSize(appBarPadding, 50)),
              if (email.isNotEmpty)
                getCustomText(
                  email,
                  theme.colorScheme.onSurfaceVariant,
                  1,
                  TextAlign.center,
                  FontWeight.w400,
                  Constant.getPercentSize(screenHeight, 2.2),
                ),
              if (email.isNotEmpty) getSpace(appBarPadding),
              Container(
                margin: EdgeInsets.all(getAppBarPadding()),
                padding: EdgeInsets.only(left: appBarPadding, right: appBarPadding),
                decoration: ShapeDecoration(
                  color: theme.cardTheme.color ?? cardColor,
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: Constant.getPercentSize(screenHeight, 2),
                      cornerSmoothing: 0.5,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: shadowColor.withOpacity(0.02),
                      blurRadius: 3,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    getSpace(appBarPadding),
                    getSettingRow("User.svg", "My Profile", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    }, context: context),
                    getSeparatorWidget(context),
                    getSettingRow("Bag.svg", "My Orders", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrdersListScreen()),
                      );
                    }, context: context),
                    getSeparatorWidget(context),
                    getSettingRow("Document.svg", "Track Order", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TrackOrderScreen()),
                      );
                    }, context: context),
                    getSeparatorWidget(context),
                    getSettingRow("Card.svg", "Categories", () {
                      Constant.sendToScreen(HomeScreen(selectedTab: 1), context);
                    }, context: context),
                    getSeparatorWidget(context),
                    getSettingRow("Setting.svg", "Change password", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                      );
                    }, context: context),
                    getSeparatorWidget(context),
                    _DarkModeToggleRow(),
                    getSpace(appBarPadding),
                  ],
                ),
              ),
              getSpace(appBarPadding),
              getButton(
                theme.colorScheme.primary,
                true,
                "Logout",
                theme.colorScheme.onPrimary,
                () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                FontWeight.w700,
                EdgeInsets.all(appBarPadding),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget getSeparatorWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getAppBarPadding()),
      child: Divider(
        height: 1,
        color: theme.dividerColor,
      ),
    );
  }
}

class _DarkModeToggleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    double iconSize = Constant.getHeightPercentSize(5);
    double subIconSize = Constant.getPercentSize(iconSize, 54);
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDark;
        return InkWell(
          onTap: () => themeProvider.mode = isDark ? ThemeMode.light : ThemeMode.dark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: getButtonShapeDecoration(
                  materialTheme.colorScheme.primary.withOpacity(0.12),
                  corner: Constant.getPercentSize(iconSize, 25),
                  withCustomCorner: true,
                ),
                child: Center(
                  child: getSvgImage("Setting.svg", subIconSize),
                ),
              ),
              getHorSpace(Constant.getPercentSize(getAppBarPadding(), 75)),
              Expanded(
                child: getCustomText(
                  'Dark mode',
                  materialTheme.colorScheme.onSurface,
                  1,
                  TextAlign.start,
                  FontWeight.w600,
                  Constant.getPercentSize(iconSize, 45),
                ),
                flex: 1,
              ),
              Switch(
                value: isDark,
                onChanged: (_) => themeProvider.mode = isDark ? ThemeMode.light : ThemeMode.dark,
                activeColor: materialTheme.colorScheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
