// ignore: file_names

class CartItem {
  CartItem({
    required this.productId,
    this.variantId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.currency = '',
    this.quantity = 1,
    this.countryFilter,
    this.hasCustomerPhoto = false,
    this.hasCustomisedTest = false,
    this.hasCustomisedShortTest = false,
    this.hasNote = false,
    this.hasSameDayBdayLoveLetter = false,
    this.noteFee = 5000,
  });

  final int productId;
  final int? variantId;
  final String name;
  final double price;
  final String? imageUrl;
  final String currency;
  int quantity;
  /// 'usa_only', 'usa_canada', or null/'all' for receiver country dropdown.
  final String? countryFilter;
  final bool hasCustomerPhoto;
  final bool hasCustomisedTest;
  final bool hasCustomisedShortTest;
  final bool hasNote;
  final bool hasSameDayBdayLoveLetter;
  final double noteFee;

  String get displayPrice => '$currency ${(price * quantity).toStringAsFixed(2)}';
  String get unitPrice => '$currency ${price.toStringAsFixed(2)}';

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      variantId: variantId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      currency: currency,
      quantity: quantity ?? this.quantity,
      countryFilter: countryFilter,
      hasCustomerPhoto: hasCustomerPhoto,
      hasCustomisedTest: hasCustomisedTest,
      hasCustomisedShortTest: hasCustomisedShortTest,
      hasNote: hasNote,
      hasSameDayBdayLoveLetter: hasSameDayBdayLoveLetter,
      noteFee: noteFee,
    );
  }
}
