<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Product::query()
            ->published()
            ->with(['brand:id,name,slug', 'displayImage'])
            ->when($request->has('category_id'), fn ($q) => $q->whereHas('categories', fn ($c) => $c->where('category_id', $request->category_id)))
            ->when($request->has('brand_id'), fn ($q) => $q->where('brand_id', $request->brand_id))
            ->when($request->filled('search'), fn ($q) => $q->where('name', 'like', '%' . $request->search . '%'));

        $perPage = min((int) $request->get('per_page', 15), 50);
        $products = $query->orderBy('id')->paginate($perPage);

        $items = $products->getCollection()->map(function ($product) {
            $prices = $product->prices(null);
            return [
                'id' => $product->id,
                'name' => $product->name,
                'slug' => $product->slug,
                'sku' => $product->sku,
                'regular_price' => (float) ($prices->regular_price ?? $product->regular_price),
                'sale_price' => (float) ($prices->sale_price ?? $product->sale_price ?? $product->regular_price),
                'currency' => gs('cur_text'),
                'in_stock' => $product->in_stock ?? 0,
                'track_inventory' => (bool) $product->track_inventory,
                'brand' => $product->brand ? ['id' => $product->brand->id, 'name' => $product->brand->name] : null,
                'image_url' => $product->mainImage(false),
                'thumb_url' => $product->mainImage(true),
            ];
        });

        return response()->json([
            'remark' => 'products_list',
            'status' => 'success',
            'message' => ['success' => ['Products retrieved.']],
            'data' => [
                'products' => $items,
                'pagination' => [
                    'current_page' => $products->currentPage(),
                    'last_page' => $products->lastPage(),
                    'per_page' => $products->perPage(),
                    'total' => $products->total(),
                ],
            ],
        ]);
    }

    public function show($id): JsonResponse
    {
        $product = Product::published()->with(['brand:id,name,slug', 'displayImage', 'productVariants'])->find($id);

        if (!$product) {
            return response()->json([
                'remark' => 'not_found',
                'status' => 'error',
                'message' => ['error' => ['Product not found or not available.']],
            ], 404);
        }

        $prices = $product->prices(null);

        return response()->json([
            'remark' => 'product_detail',
            'status' => 'success',
            'message' => ['success' => ['Product retrieved.']],
            'data' => [
                'product' => [
                    'id' => $product->id,
                    'name' => $product->name,
                    'slug' => $product->slug,
                    'sku' => $product->sku,
                    'regular_price' => (float) ($prices->regular_price ?? $product->regular_price),
                    'sale_price' => (float) ($prices->sale_price ?? $product->sale_price ?? $product->regular_price),
                    'currency' => gs('cur_text'),
                    'in_stock' => $product->in_stock ?? 0,
                    'track_inventory' => (bool) $product->track_inventory,
                    'brand' => $product->brand ? ['id' => $product->brand->id, 'name' => $product->brand->name] : null,
                    'image_url' => $product->mainImage(false),
                    'thumb_url' => $product->mainImage(true),
                    'variants' => $product->productVariants->map(fn ($v) => [
                        'id' => $v->id,
                        'regular_price' => (float) $v->regular_price,
                        'sale_price' => (float) ($v->sale_price ?? $v->regular_price),
                        'in_stock' => $v->in_stock ?? 0,
                    ]),
                ],
            ],
        ]);
    }
}
