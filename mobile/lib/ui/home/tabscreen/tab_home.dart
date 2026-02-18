// ignore: file_names
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/widget_utils.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/models/category.dart';
import 'package:giftfr/models/api_response.dart';
import 'package:giftfr/models/product.dart';
import 'package:giftfr/models/slider.dart' as app;
import 'package:giftfr/screens/product_detail_screen.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  List<app.SliderItem> _sliders = [];
  List<CategoryItem> _categories = [];
  List<ProductItem> _products = [];
  bool _loading = true;
  String? _error;
  int _sliderIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final api = context.read<ApiService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      api.getSliders(),
      api.getCategories(),
      api.getProducts(page: 1, perPage: 20),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (results[0].success && results[0].data != null) {
        _sliders = results[0].data!;
      }
      if (results[1].success && results[1].data != null) {
        _categories = results[1].data!;
      }
      final productRes = results[2] as ApiResponse<ProductListData>;
      if (productRes.success && productRes.data != null) {
        _products = productRes.data!.products;
        _error = null;
      } else {
        _error = productRes.error ?? 'Failed to load products';
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
    double carousalHeight = Constant.getPercentSize(screenWidth, 32);
    double categoryHeight = Constant.getPercentSize(screenHeight, 14);
    double categoryWidth = Constant.getPercentSize(categoryHeight, 58);
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
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Slider from backend
                  _buildSliderSection(carousalHeight, appbarPadding, screenHeight),
                  // Categories from backend
                  if (_categories.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: appbarPadding,
                        vertical: Constant.getPercentSize(screenHeight, 1),
                      ),
                      child: getCustomText(
                        "Categories",
                        fontBlack,
                        1,
                        TextAlign.start,
                        FontWeight.w800,
                        Constant.getPercentSize(screenHeight, 2.5),
                      ),
                    ),
                    SizedBox(
                      height: categoryHeight,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: appbarPadding),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return Padding(
                            padding: EdgeInsets.only(right: appbarPadding),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProductListScreen(categoryId: cat.id),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _categoryImageUrl(cat) != null
                                          ? CachedNetworkImage(
                                              imageUrl: _categoryImageUrl(cat)!,
                                              width: categoryWidth,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                              errorWidget: (_, __, ___) => _categoryPlaceholder(categoryWidth, categoryHeight),
                                            )
                                          : _categoryPlaceholder(categoryWidth, categoryHeight),
                                    ),
                                  ),
                                  SizedBox(height: Constant.getPercentSize(categoryHeight, 8)),
                                  SizedBox(
                                    width: categoryWidth,
                                    child: getCustomText(
                                      cat.name,
                                      fontBlack,
                                      1,
                                      TextAlign.center,
                                      FontWeight.w600,
                                      Constant.getPercentSize(categoryHeight, 12)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: Constant.getPercentSize(screenHeight, 1.5)),
                  ],
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
                            onPressed: _loadAll,
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

  Widget _buildSliderSection(double carousalHeight, double appbarPadding, double screenHeight) {
    if (_sliders.isEmpty) {
      return Container(
        height: carousalHeight,
        margin: EdgeInsets.all(Constant.getPercentSize(screenHeight, 1.5)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Constant.getPercentSize(carousalHeight, 8)),
          color: primaryColor.withOpacity(0.2),
        ),
        child: Center(
          child: getCustomText(
            "Gift Store",
            Colors.white,
            1,
            TextAlign.center,
            FontWeight.bold,
            Constant.getPercentSize(carousalHeight, 10),
          ),
        ),
      );
    }
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _sliders.length,
          options: CarouselOptions(
            height: carousalHeight,
            viewportFraction: 1.0,
            autoPlay: true,
            enlargeCenterPage: false,
            onPageChanged: (index, _) => setState(() => _sliderIndex = index),
          ),
          itemBuilder: (context, index, realIndex) {
            final slide = _sliders[index];
            final imageUrl = slide.imageUrl;
            Widget content;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              content = CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (_, __, ___) => Container(color: primaryColor.withOpacity(0.2), child: Center(child: getCustomText("Gift Store", Colors.white, 1, TextAlign.center, FontWeight.bold, 18))),
              );
            } else {
              content = Container(
                color: primaryColor.withOpacity(0.2),
                child: Center(
                  child: getCustomText("Gift Store", Colors.white, 1, TextAlign.center, FontWeight.bold, Constant.getPercentSize(carousalHeight, 10)),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: appbarPadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Constant.getPercentSize(carousalHeight, 8)),
                child: slide.link != null && slide.link!.isNotEmpty
                    ? GestureDetector(
                        onTap: () => launchUrl(Uri.parse(slide.link!)),
                        child: content,
                      )
                    : content,
              ),
            );
          },
        ),
        if (_sliders.length > 1)
          Padding(
            padding: EdgeInsets.only(top: Constant.getPercentSize(screenHeight, 0.8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_sliders.length, (i) {
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _sliderIndex == i ? primaryColor : primaryColor.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        SizedBox(height: Constant.getPercentSize(screenHeight, 1.5)),
      ],
    );
  }

  String? _categoryImageUrl(CategoryItem cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) return cat.imageUrl;
    if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty) return cat.iconUrl;
    return null;
  }

  Widget _categoryPlaceholder(double categoryWidth, double categoryHeight) {
    return Container(
      width: categoryWidth,
      color: primaryColor.withOpacity(0.2),
      child: Icon(Icons.category, color: primaryColor, size: Constant.getPercentSize(categoryHeight, 35)),
    );
  }

  Widget _productCard(BuildContext context, ProductItem p, double w, double h) {
    final imageUrl = p.thumbUrl ?? p.imageUrl;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: p.id),
          ),
        ),
      ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Constant.getPercentSize(h, 4)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: backgroundColor, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (_, __, ___) => Container(color: backgroundColor, child: Icon(Icons.card_giftcard, size: Constant.getPercentSize(h, 25), color: primaryColor)),
                      )
                    : Container(
                        color: backgroundColor,
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
