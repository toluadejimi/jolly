// ignore: file_names
import 'package:flutter/material.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import '../../../constants/constant.dart';
import '../../../constants/widget_utils.dart';

class TabCart extends StatefulWidget {
  const TabCart({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabCartState();
}

class _TabCartState extends State<TabCart> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double appBarPadding = getAppBarPadding();
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: Column(
        children: [
          getDefaultHeader(context, "My Cart", () {}, (value) {},
              withFilter: false, isShowBack: false, isShowSearch: false),
          Expanded(
            child: getEmptyWidget(
              "empty_cart.svg",
              "Your cart is empty",
              "Add items from the store to checkout.",
              "Browse products",
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProductListScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
