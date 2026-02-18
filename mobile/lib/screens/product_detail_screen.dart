import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_response.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
      ),
      body: FutureBuilder<ApiResponse<ProductDetail>>(
        future: context.read<ApiService>().getProduct(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final res = snapshot.data;
          if (res == null || !res.success || res.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(res?.error ?? 'Failed to load product'),
              ),
            );
          }
          final p = res.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  p.displayPrice,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (p.brand != null) ...[
                  const SizedBox(height: 8),
                  Text('Brand: ${p.brand!.name}'),
                ],
                if (p.sku != null) ...[
                  const SizedBox(height: 4),
                  Text('SKU: ${p.sku}'),
                ],
                const SizedBox(height: 16),
                Text(
                  'In stock: ${p.inStock}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
