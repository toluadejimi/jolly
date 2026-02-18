// ignore: file_names
import 'package:flutter/material.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import '../../../constants/widget_utils.dart';

class TabFavourite extends StatefulWidget {
  const TabFavourite({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabFavouriteState();
}

class _TabFavouriteState extends State<TabFavourite> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double appbarPadding = getAppBarPadding();
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          getDefaultHeader(context, "My Favourite", () {}, (value) {},
              withFilter: false, isShowBack: false),
          Expanded(
            child: getEmptyWidget(
              "empty_card.svg",
              "No favourites yet",
              "Save items you like to find them here.",
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
