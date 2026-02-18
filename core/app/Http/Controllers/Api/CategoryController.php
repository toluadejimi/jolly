<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;

class CategoryController extends Controller
{
    /**
     * List categories (parent only, with image URL for app).
     */
    public function index(): JsonResponse
    {
        $categories = Category::isParent()
            ->orderBy('name')
            ->get();

        $items = $categories->map(function ($category) {
            return [
                'id' => $category->id,
                'name' => $category->name,
                'slug' => $category->slug,
                'image_url' => $category->categoryImage(),
                'icon_url' => $category->categoryIcon(),
            ];
        });

        return response()->json([
            'remark' => 'categories_list',
            'status' => 'success',
            'message' => ['success' => ['Categories retrieved.']],
            'data' => ['categories' => $items],
        ]);
    }
}
