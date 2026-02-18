import 'package:flutter/material.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:math' as math;
import 'constant.dart';
import 'color_data.dart';

// ignore: must_be_immutable
class CustomAnimatedBottomBar extends StatelessWidget {
  CustomAnimatedBottomBar(
      {Key? key,
      this.selectedIndex = 0,
      this.showElevation = true,
      this.iconSize = 24,
      this.backgroundColor,
      this.itemCornerRadius = 50,
      this.containerHeight = 56,
      this.animationDuration = const Duration(milliseconds: 300),
      this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
      required this.items,
      required this.onItemSelected,
      this.curve = Curves.easeInOut,
      this.totalItemCount = 1,
      this.isDark = false})
      : assert(items.length >= 2 && items.length <= 5),
        super(key: key);

  final int selectedIndex;
  final double iconSize;
  final Color? backgroundColor;
  final bool showElevation;
  final Duration animationDuration;
  final List<BottomNavyBarItem> items;
  final ValueChanged<int> onItemSelected;
  final MainAxisAlignment mainAxisAlignment;
  final double itemCornerRadius;
  final double containerHeight;
  final Curve curve;
  final bool isDark;
  int totalItemCount;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          if (showElevation)
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
            ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: containerHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              var index = items.indexOf(item);
              return GestureDetector(
                onTap: () => onItemSelected(index),
                child: _ItemWidget(
                  item: item,
                  containerHeight: containerHeight,
                  iconSize: iconSize,
                  isSelected: index == selectedIndex,
                  backgroundColor: bgColor,
                  itemCornerRadius: itemCornerRadius,
                  animationDuration: animationDuration,
                  curve: curve,
                  totalItem: totalItemCount,
                  isDark: isDark,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ItemWidget extends StatelessWidget {
  final double iconSize;
  final bool isSelected;
  final BottomNavyBarItem item;
  final Color backgroundColor;
  final double itemCornerRadius;
  final double containerHeight;
  final Duration animationDuration;
  final Curve curve;
  final int totalItem;
  final bool isDark;

  const _ItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.backgroundColor,
    required this.animationDuration,
    required this.itemCornerRadius,
    required this.containerHeight,
    required this.iconSize,
    required this.totalItem,
    this.curve = Curves.linear,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    double width = (SizeConfig.safeBlockHorizontal! * 100) / totalItem;
    double containerSize = math.min(width, containerHeight);

    return Semantics(
      container: true,
      selected: isSelected,
      child: AnimatedContainer(
        height: double.maxFinite,
        duration: animationDuration,
        curve: curve,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            width: width,
            color: backgroundColor,
            child: SizedBox(
              height: containerHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: Constant.getPercentSize(containerSize, 70),
                    height: Constant.getPercentSize(containerSize, 70),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isSelected && isDark)
                        BoxShadow(
                          color: item.activeColor.withOpacity(0.45),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      if (isSelected && !isDark)
                        BoxShadow(
                          color: shadowColor.withOpacity(0.08),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                    ],
                    color: isSelected ? item.activeColor : Colors.transparent,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      Constant.assetImagePath + item.imageName!,
                      colorFilter: isSelected
                          ? ColorFilter.mode(
                              isDark ? Colors.black : Colors.white,
                              BlendMode.srcIn,
                            )
                          : null,
                      height: (item.iconSize! * 1.1),
                    ),
                  ),
                ),
                if (item.title != null && item.title!.isNotEmpty) ...[
                  SizedBox(height: Constant.getPercentSize(containerSize, 4)),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.title!,
                        style: TextStyle(
                          fontSize: Constant.getPercentSize(containerSize, 18),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? item.activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavyBarItem {
  BottomNavyBarItem({
    this.activeColor = Colors.blue,
    this.textAlign,
    this.inactiveColor,
    this.imageName,
    this.iconSize,
    this.title,
  });

  final Color activeColor;
  final Color? inactiveColor;
  final TextAlign? textAlign;
  final String? imageName;
  final String? title;
  final double? iconSize;
}
