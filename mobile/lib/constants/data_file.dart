// Static content only. All product/cart/order data comes from the backend API.
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/models/model_banner.dart';
import 'package:giftfr/models/model_cart.dart';
import 'package:giftfr/models/model_category.dart';
import 'package:giftfr/models/model_intro.dart';
import 'package:giftfr/models/model_my_order.dart';
import 'package:giftfr/models/model_trending.dart';

import '../models/address_model.dart';
import '../models/model_category_items.dart';
import '../models/payment_card_model.dart';
import '../models/product_model.dart';

class DataFile {
  static List<ModelBanner> getAllBanner() => [];

  static List<ProductModel> getCartModel() => [];

  static List<ModelMyOrder> getMyOrders() => [];

  static List<PaymentCardModel> getPaymentCardList() => [];

  static List<AddressModel> getAddressList() => [];

  static List<ModelCategory> getAllCategory() => [];

  static List<ModelCategoryItems> getAllCategoryItems() => [];

  static List<ModelTrending> getAllTrendingProduct() => [];

  static List<ModelTrending> getAllPopularProduct() => [];

  static List<ModelCart> getAllCartList() => [];

  static List<String> sizeList = ["S", "M", "L", "XL", "XXL"];
  static List<String> colorList = [
    "color1.png",
    "color2.png",
    "color3.png",
    "color4.png",
    "color5.png",
  ];

  /// Onboarding slides (static content; not from API).
  static List<ModelIntro> getAllIntroData() {
    final introImage = "banner.png";
    return [
      ModelIntro(
        1,
        "Find the perfect gift\n for every occasion",
        "Browse our collection and send something special\nto the people you care about.",
        introImage,
      ),
      ModelIntro(
        2,
        "Track your orders\n easily",
        "Enter your order number and see delivery status,\nestimated delivery and tracking link.",
        introImage,
      ),
      ModelIntro(
        3,
        "Secure checkout\n and fast delivery",
        "Shop with confidence. We keep your details safe\nand deliver on time.",
        introImage,
      ),
      ModelIntro(
        4,
        "Welcome to Gift Store",
        "Sign in or create an account to start shopping\nand managing your orders.",
        introImage,
      ),
    ];
  }
}
