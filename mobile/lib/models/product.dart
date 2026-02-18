class ProductItem {
  ProductItem({
    required this.id,
    required this.name,
    required this.slug,
    this.sku,
    required this.regularPrice,
    required this.salePrice,
    required this.currency,
    this.inStock = 0,
    this.trackInventory = false,
    this.brand,
    this.imageUrl,
    this.thumbUrl,
    this.badge,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final badgeRaw = json['badge'] ?? json['product_badge'] ?? json['tag'];
    final badge = badgeRaw is String && badgeRaw.trim().isNotEmpty
        ? badgeRaw.trim()
        : null;
    return ProductItem(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sku: json['sku'] as String?,
      regularPrice: (json['regular_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? '',
      inStock: (json['in_stock'] as num?)?.toInt() ?? 0,
      trackInventory: json['track_inventory'] as bool? ?? false,
      brand: json['brand'] != null
          ? ProductBrand.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      imageUrl: json['image_url'] as String?,
      thumbUrl: json['thumb_url'] as String?,
      badge: badge,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? sku;
  final double regularPrice;
  final double salePrice;
  final String currency;
  final int inStock;
  final bool trackInventory;
  final ProductBrand? brand;
  final String? imageUrl;
  final String? thumbUrl;
  final String? badge;

  String get displayPrice => salePrice < regularPrice
      ? '$currency $salePrice'
      : '$currency $regularPrice';
}

class ProductBrand {
  ProductBrand({required this.id, required this.name});

  factory ProductBrand.fromJson(Map<String, dynamic> json) {
    return ProductBrand(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

class ProductListData {
  ProductListData({required this.products, required this.pagination});

  factory ProductListData.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>? ?? [];
    final pag = json['pagination'] as Map<String, dynamic>? ?? {};
    return ProductListData(
      products: list
          .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(pag),
    );
  }

  final List<ProductItem> products;
  final Pagination pagination;
}

class Pagination {
  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 15,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
}

class ProductDetail {
  ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.sku,
    required this.regularPrice,
    required this.salePrice,
    required this.currency,
    this.inStock = 0,
    this.trackInventory = false,
    this.brand,
    this.variants = const [],
    this.imageUrl,
    this.thumbUrl,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final v = json['variants'] as List<dynamic>? ?? [];
    return ProductDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sku: json['sku'] as String?,
      regularPrice: (json['regular_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? '',
      inStock: (json['in_stock'] as num?)?.toInt() ?? 0,
      trackInventory: json['track_inventory'] as bool? ?? false,
      brand: json['brand'] != null
          ? ProductBrand.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      variants: v
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['image_url'] as String?,
      thumbUrl: json['thumb_url'] as String?,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? sku;
  final double regularPrice;
  final double salePrice;
  final String currency;
  final int inStock;
  final bool trackInventory;
  final ProductBrand? brand;
  final List<ProductVariant> variants;
  final String? imageUrl;
  final String? thumbUrl;

  String get displayPrice => salePrice < regularPrice
      ? '$currency $salePrice'
      : '$currency $regularPrice';
}

class ProductVariant {
  ProductVariant({
    required this.id,
    required this.regularPrice,
    required this.salePrice,
    this.inStock = 0,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      regularPrice: (json['regular_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      inStock: (json['in_stock'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final double regularPrice;
  final double salePrice;
  final int inStock;
}
