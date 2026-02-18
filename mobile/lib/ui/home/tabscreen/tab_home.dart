// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/widget_utils.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/models/product.dart';
import 'package:giftfr/screens/product_detail_screen.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/ui/home/home_screen.dart';

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  List<ProductItem> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final api = context.read<ApiService>();
    final res = await api.getProducts(page: 1, perPage: 20);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _products = res.data!.products;
        _error = null;
      } else {
        _error = res.error ?? 'Failed to load products';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double appbarPadding = getAppBarPadding();
    double iconSize = Constant.getPercentSize(screenHeight, 3);
    double carousalHeight = Constant.getPercentSize(screenWidth, 28);
    double marginPopular = appbarPadding;
    int crossAxisCountPopular = 2;
    double popularWidth =
        (screenWidth - ((crossAxisCountPopular - 1) * marginPopular)) /
            crossAxisCountPopular;
    double popularHeight = Constant.getPercentSize(screenHeight, 32);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: primaryColor,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: appbarPadding),
            child: AppBar(
              elevation: 0,
              backgroundColor: primaryColor,
              leadingWidth: Constant.getPercentSize(screenHeight, 18),
              leading: Image.asset(
                Constant.assetImagePath + "banner.png",
                height: Constant.getPercentSize(screenHeight, 4),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              actions: [
                InkWell(
                  child: getSvgImage("Bag.svg", iconSize, color: Colors.white),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(selectedTab: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: backgroundColor,
              width: double.infinity,
              height: double.infinity,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Promo strip
                  Container(
                    height: carousalHeight,
                    margin: EdgeInsets.all(Constant.getPercentSize(screenHeight, 1.5)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Constant.getPercentSize(carousalHeight, 8)),
                      child: Image.asset(
                        Constant.assetImagePath + "banner.png",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: primaryColor.withOpacity(0.2),
                          child: Center(
                            child: getCustomText(
                              "Gift Store",
                              Colors.white,
                              1,
                              TextAlign.center,
                              FontWeight.bold,
                              Constant.getPercentSize(carousalHeight, 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Products section header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: appbarPadding,
                      vertical: Constant.getPercentSize(screenHeight, 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        getCustomText(
                          "Products",
                          fontBlack,
                          1,
                          TextAlign.start,
                          FontWeight.w800,
                          Constant.getPercentSize(screenHeight, 3),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProductListScreen(),
                              ),
                            );
                          },
                          child: getCustomText(
                            "View all",
                            primaryColor,
                            1,
                            TextAlign.start,
                            FontWeight.w400,
                            Constant.getPercentSize(screenHeight, 2.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Products grid or loading/error
                  if (_loading)
                    Padding(
                      padding: EdgeInsets.all(appbarPadding * 2),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: EdgeInsets.all(appbarPadding),
                      child: Column(
                        children: [
                          getCustomText(
                            _error!,
                            greyFont,
                            3,
                            TextAlign.center,
                            FontWeight.w400,
                            Constant.getPercentSize(screenHeight, 2.2),
                          ),
                          SizedBox(height: Constant.getPercentSize(screenHeight, 2)),
                          TextButton(
                            onPressed: _loadProducts,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  else if (_products.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(appbarPadding),
                      child: getCustomText(
                        "No products yet.",
                        greyFont,
                        1,
                        TextAlign.center,
                        FontWeight.w400,
                        Constant.getPercentSize(screenHeight, 2.2),
                      ),
                    )
                  else
                    GridView.count(
                      padding: EdgeInsets.only(
                        left: marginPopular,
                        right: marginPopular,
                        bottom: marginPopular,
                        top: 0,
                      ),
                      crossAxisCount: crossAxisCountPopular,
                      crossAxisSpacing: marginPopular,
                      mainAxisSpacing: marginPopular,
                      childAspectRatio: popularWidth / popularHeight,
                      shrinkWrap: true,
                      primary: false,
                      children: _products.map((p) => _productCard(context, p, popularWidth, popularHeight)).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, ProductItem p, double w, double h) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: p.id),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(Constant.getPercentSize(h, 3.3)),
        decoration: ShapeDecoration(
          color: cardColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: Constant.getPercentSize(h, 4),
              cornerSmoothing: 0.5,
            ),
          ),
          shadows: const [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1.2,
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: ShapeDecoration(
                  color: backgroundColor,
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: Constant.getPercentSize(h, 4),
                      cornerSmoothing: 0.3,
                    ),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.card_giftcard, size: Constant.getPercentSize(h, 25), color: primaryColor),
                ),
              ),
            ),
            SizedBox(height: Constant.getPercentSize(h, 4)),
            getCustomText(
              p.name,
              fontBlack,
              2,
              TextAlign.start,
              FontWeight.bold,
              Constant.getPercentSize(h, 5.5),
            ),
            SizedBox(height: Constant.getPercentSize(h, 2.5)),
            getCustomText(
              p.displayPrice,
              fontBlack,
              1,
              TextAlign.start,
              FontWeight.w400,
              Constant.getPercentSize(h, 5.5),
            ),
          ],
        ),
      ),
    );
  }
}
