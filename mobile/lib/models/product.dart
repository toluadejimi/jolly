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
    this.hasVariants = false,
    this.todayDelivery = false,
    this.usaExpressDelivery = false,
    this.usaDelivery = false,
    this.allCountriesDelivery = false,
    this.customerPhoto = false,
    this.customisedTest = false,
    this.customisedShortTest = false,
    this.note = false,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final badgeRaw = json['badge'] ?? json['product_badge'] ?? json['tag'];
    final badge = badgeRaw is String && badgeRaw.trim().isNotEmpty
        ? badgeRaw.trim()
        : null;
    final hasVariants = json['has_variants'] as bool? ?? false;
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
      hasVariants: hasVariants,
      todayDelivery: json['today_delivery'] as bool? ?? false,
      usaExpressDelivery: json['usa_express_delivery'] as bool? ?? false,
      usaDelivery: json['usa_delivery'] as bool? ?? false,
      allCountriesDelivery: json['all_countries_delivery'] as bool? ?? false,
      customerPhoto: ProductDetail._parseBool(json['customer_photo']),
      customisedTest: ProductDetail._parseBool(json['customised_test']),
      customisedShortTest: ProductDetail._parseBool(json['customised_short_test']),
      note: ProductDetail._parseBool(json['note']),
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
  final bool hasVariants;
  final bool todayDelivery;
  final bool usaExpressDelivery;
  final bool usaDelivery;
  final bool allCountriesDelivery;
  final bool customerPhoto;
  final bool customisedTest;
  final bool customisedShortTest;
  final bool note;

  /// Delivery badges matching web product_images.blade.php (Today Delivery, US Express, US Delivery, All Countries).
  List<String> get deliveryBadges {
    final list = <String>[];
    if (todayDelivery) list.add('Today Delivery');
    if (usaExpressDelivery) list.add('🇺🇸 US Express Shipping');
    if (usaDelivery) list.add('🇺🇸 US Delivery');
    if (allCountriesDelivery) list.add('🌎 All Countries Delivery');
    return list;
  }

  /// All badges to show on card: delivery badges first, then generic badge if any.
  List<String> get displayBadges {
    final list = List<String>.from(deliveryBadges);
    if (badge != null && badge!.isNotEmpty) list.add(badge!);
    return list;
  }

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
    this.galleryUrls = const [],
    this.description,
    this.badge,
    this.todayDelivery = false,
    this.usaExpressDelivery = false,
    this.usaDelivery = false,
    this.allCountriesDelivery = false,
    this.customerPhoto = false,
    this.customisedTest = false,
    this.customisedShortTest = false,
    this.note = false,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final v = json['variants'] as List<dynamic>? ?? [];
    final galleryList = json['gallery_urls'] as List<dynamic>? ?? [];
    final badgeRaw = json['badge'] ?? json['product_badge'] ?? json['tag'];
    final badge = badgeRaw is String && badgeRaw.toString().trim().isNotEmpty
        ? badgeRaw.toString().trim()
        : null;
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
      galleryUrls: galleryList.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(),
      description: json['description'] as String?,
      badge: badge,
      todayDelivery: json['today_delivery'] as bool? ?? false,
      usaExpressDelivery: json['usa_express_delivery'] as bool? ?? false,
      usaDelivery: json['usa_delivery'] as bool? ?? false,
      allCountriesDelivery: json['all_countries_delivery'] as bool? ?? false,
      customerPhoto: _parseBool(json['customer_photo']),
      customisedTest: _parseBool(json['customised_test']),
      customisedShortTest: _parseBool(json['customised_short_test']),
      note: _parseBool(json['note']),
    );
  }

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
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
  final List<String> galleryUrls;
  final String? description;
  final String? badge;
  final bool todayDelivery;
  final bool usaExpressDelivery;
  final bool usaDelivery;
  final bool allCountriesDelivery;
  final bool customerPhoto;
  final bool customisedTest;
  final bool customisedShortTest;
  final bool note;

  /// All image URLs to show: gallery if present, else main image.
  List<String> get displayImageUrls {
    if (galleryUrls.isNotEmpty) return galleryUrls;
    final main = imageUrl ?? thumbUrl;
    return main != null && main.isNotEmpty ? [main] : [];
  }

  List<String> get deliveryBadges {
    final list = <String>[];
    if (todayDelivery) list.add('Today Delivery');
    if (usaExpressDelivery) list.add('🇺🇸 US Express Shipping');
    if (usaDelivery) list.add('🇺🇸 US Delivery');
    if (allCountriesDelivery) list.add('🌎 All Countries Delivery');
    return list;
  }

  List<String> get displayBadges {
    final list = List<String>.from(deliveryBadges);
    if (badge != null && badge!.isNotEmpty) list.add(badge!);
    return list;
  }

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
    this.name,
    this.imageUrl,
    this.galleryUrls = const [],
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final nameRaw = json['name'] ?? json['option'] ?? json['title'];
    final name = nameRaw is String && nameRaw.trim().isNotEmpty
        ? nameRaw.trim()
        : null;
    final galleryList = json['gallery_urls'] as List<dynamic>? ?? [];
    return ProductVariant(
      id: json['id'] as int,
      regularPrice: (json['regular_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      inStock: (json['in_stock'] as num?)?.toInt() ?? 0,
      name: name,
      imageUrl: json['image_url'] as String?,
      galleryUrls: galleryList.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(),
    );
  }

  final int id;
  final double regularPrice;
  final double salePrice;
  final int inStock;
  final String? name;
  final String? imageUrl;
  final List<String> galleryUrls;

  /// Image URLs to show for this variant: variant gallery if any, else variant image, else empty.
  List<String> get displayImageUrls {
    if (galleryUrls.isNotEmpty) return galleryUrls;
    return imageUrl != null && imageUrl!.isNotEmpty ? [imageUrl!] : [];
  }
}
