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
  });

  final int productId;
  final int? variantId;
  final String name;
  final double price;
  final String? imageUrl;
  final String currency;
  int quantity;

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
    );
  }
}
