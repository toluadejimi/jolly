// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/providers/theme_provider.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:giftfr/ui/login/login_screen.dart';
import 'package:giftfr/screens/track_order_screen.dart';
import 'package:provider/provider.dart';

import '../../../constants/constant.dart';
import '../../../constants/pref_data.dart';
import '../../../constants/widget_utils.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TabProfile();
  }
}

class _TabProfile extends State<TabProfile> {
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
          Container(
              width: imgHeight,
              height: imgHeight,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image:
                          AssetImage(Constant.assetImagePath + "banner.png"),
                      fit: BoxFit.cover))

              // image: DecorationImage(image: AssetImage(Constant.assetImagePath+"Profile.png"))),
              // child: ClipRRect(
              //   borderRadius: BorderRadius.all(Radius.circular(imgRadius)),
              //   child: getSvgImage("Profile.svg", double.infinity),
              // ),
              ),
          getSpace(appBarPadding),
          // getSpace(Constant.getPercentSize(screenHeight,1)),
          getCustomText("Jerome Bell", theme.colorScheme.onSurface, 1, TextAlign.center,
              FontWeight.bold, Constant.getPercentSize(screenHeight, 2.7)),
          getSpace(Constant.getPercentSize(appBarPadding, 50)),
          getCustomText("jeromebell@gmail.com", theme.colorScheme.onSurfaceVariant, 1, TextAlign.center,
              FontWeight.w400, Constant.getPercentSize(screenHeight, 2.2)),
          getSpace(appBarPadding),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(getAppBarPadding()),
              padding: EdgeInsets.only(
                  left: appBarPadding,
                  right: appBarPadding),
              decoration: ShapeDecoration(
                  color: theme.cardTheme.color ?? cardColor,
                  shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                          cornerRadius:
                              Constant.getPercentSize(screenHeight, 2),
                          cornerSmoothing: 0.5)),
                  shadows: [
                    BoxShadow(
                        color: shadowColor.withOpacity(0.02),
                        blurRadius: 3,
                        spreadRadius: 4)
                  ]),
              child: ListView(
                padding: EdgeInsets.zero,
                primary: true,
                shrinkWrap: true,
                children: [
                  getSpace(appBarPadding),
                  getSettingRow("User.svg", "My Profile", () {}, context: context),
                  getSeparatorWidget(),
                  getSettingRow("Bag.svg", "My Orders", () {}, context: context),
                  getSeparatorWidget(),
                  getSettingRow("Document.svg", "Track Order", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrackOrderScreen(),
                      ),
                    );
                  }, context: context),
                  getSeparatorWidget(),
                  getSettingRow("fav_fill.svg", "My Favourites", () {
                    Constant.sendToScreen(HomeScreen(selectedTab: 1), context);

                  }, context: context),
                  getSeparatorWidget(),
                  getSettingRow("shipping_location.svg", "Shipping Address", () {}, context: context),
                  getSeparatorWidget(),
                  getSettingRow("Card.svg", "My Cards", () {}, context: context),
                  getSeparatorWidget(),
                  getSettingRow("Setting.svg", "Settings", () {}, context: context),
                  getSeparatorWidget(),
                  _ThemeOptionRow(title: 'Light mode', themeMode: ThemeMode.light),
                  getSeparatorWidget(),
                  _ThemeOptionRow(title: 'Dark mode', themeMode: ThemeMode.dark),
                  getSpace(appBarPadding),

                ],
              ),
              
            ),
            flex: 1,
          ),
          getButton(theme.colorScheme.primary, true, "Logout", theme.colorScheme.onPrimary, () {
            PrefData.setLogIn(false);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }, FontWeight.w700, EdgeInsets.all(appBarPadding))
        ],
      ),
    );
  }

  Widget getSeparatorWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getAppBarPadding()),
      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }
}

class _ThemeOptionRow extends StatelessWidget {
  const _ThemeOptionRow({required this.title, required this.themeMode});

  final String title;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    double iconSize = Constant.getHeightPercentSize(5);
    double subIconSize = Constant.getPercentSize(iconSize, 54);
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isSelected = themeProvider.mode == themeMode;
        return InkWell(
          onTap: () => themeProvider.mode = themeMode,
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
                  title,
                  materialTheme.colorScheme.onSurface,
                  1,
                  TextAlign.start,
                  FontWeight.w600,
                  Constant.getPercentSize(iconSize, 45),
                ),
                flex: 1,
              ),
              isSelected
                  ? Icon(Icons.check, size: subIconSize * 1.2, color: materialTheme.colorScheme.primary)
                  : getSvgImage("ArrowRight.svg", subIconSize),
            ],
          ),
        );
      },
    );
  }
}
