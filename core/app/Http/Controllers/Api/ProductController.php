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
            ->withCount('productVariants')
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
                'has_variants' => ($product->product_variants_count ?? 0) > 0,
                'today_delivery' => (bool) ($product->today_delivery ?? 0),
                'usa_express_delivery' => (bool) ($product->usa_express_delivery ?? 0),
                'usa_delivery' => (bool) ($product->usa_delivery ?? 0),
                'all_countries_delivery' => (bool) ($product->all_countries_delivery ?? 0),
                'customer_photo' => (int) ($product->customer_photo ?? 0),
                'customised_test' => (int) ($product->customised_test ?? 0),
                'customised_short_test' => (string) ($product->customised_short_test ?? '0'),
                'note' => (int) ($product->note ?? 0),
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
        $product = Product::published()
            ->with([
                'brand:id,name,slug',
                'displayImage',
                'galleryImages',
                'productVariants' => fn ($q) => $q->published()->with(['displayImage', 'galleryImages']),
            ])
            ->find($id);
        $attributeValueIds = $product ? $product->productVariants->pluck('attribute_values')->filter()->flatten()->unique()->values()->all() : [];
        $attributeLabelById = [];
        if (!empty($attributeValueIds)) {
            foreach (\App\Models\AttributeValue::whereIn('id', $attributeValueIds)->get() as $av) {
                $attributeLabelById[$av->id] = $av->value ?? $av->name ?? (string) $av->id;
            }
        }

        if (!$product) {
            return response()->json([
                'remark' => 'not_found',
                'status' => 'error',
                'message' => ['error' => ['Product not found or not available.']],
            ], 404);
        }

        $prices = $product->prices(null);

        // Gallery: main image first, then gallery (match web product_images)
        $galleryUrls = [];
        $mainUrl = $product->mainImage(false);
        if ($mainUrl) {
            $galleryUrls[] = $mainUrl;
        }
        $galleryCollection = $product->galleryImages ?? collect();
        foreach ($galleryCollection as $media) {
            $url = $media->full_url ?? url($media->path . '/' . $media->file_name);
            if (!in_array($url, $galleryUrls)) {
                $galleryUrls[] = $url;
            }
        }

        $variantsPayload = $product->productVariants->map(function ($v) use ($attributeLabelById) {
            $ids = is_array($v->attribute_values) ? $v->attribute_values : json_decode($v->attribute_values ?? '[]', true);
            $name = $ids ? implode(', ', array_filter(array_map(fn ($id) => $attributeLabelById[$id] ?? null, $ids))) : null;
            $variantImageUrl = $v->mainImage(false);
            $variantGalleryUrls = [];
            if ($variantImageUrl) {
                $variantGalleryUrls[] = $variantImageUrl;
            }
            foreach ($v->galleryImages ?? [] as $media) {
                $url = $media->full_url ?? url($media->path . '/' . $media->file_name);
                if (!in_array($url, $variantGalleryUrls)) {
                    $variantGalleryUrls[] = $url;
                }
            }
            return [
                'id' => $v->id,
                'regular_price' => (float) $v->regular_price,
                'sale_price' => (float) ($v->sale_price ?? $v->regular_price),
                'in_stock' => $v->in_stock ?? 0,
                'name' => $name ?: ('Option #' . $v->id),
                'image_url' => $variantImageUrl,
                'gallery_urls' => array_values($variantGalleryUrls),
            ];
        });

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
                    'description' => $product->description ?? '',
                    'regular_price' => (float) ($prices->regular_price ?? $product->regular_price),
                    'sale_price' => (float) ($prices->sale_price ?? $product->sale_price ?? $product->regular_price),
                    'currency' => gs('cur_text'),
                    'in_stock' => $product->in_stock ?? 0,
                    'track_inventory' => (bool) $product->track_inventory,
                    'brand' => $product->brand ? ['id' => $product->brand->id, 'name' => $product->brand->name] : null,
                    'image_url' => $product->mainImage(false),
                    'thumb_url' => $product->mainImage(true),
                    'gallery_urls' => array_values($galleryUrls),
                    'today_delivery' => (bool) ($product->today_delivery ?? 0),
                    'usa_express_delivery' => (bool) ($product->usa_express_delivery ?? 0),
                    'usa_delivery' => (bool) ($product->usa_delivery ?? 0),
                    'all_countries_delivery' => (bool) ($product->all_countries_delivery ?? 0),
                    'customer_photo' => (int) ($product->customer_photo ?? 0),
                    'customised_test' => (int) ($product->customised_test ?? 0),
                    'customised_short_test' => (string) ($product->customised_short_test ?? '0'),
                    'note' => (int) ($product->note ?? 0),
                    'variants' => $variantsPayload,
                ],
            ],
        ]);
    }
}
