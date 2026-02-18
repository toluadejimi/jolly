<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class SliderController extends Controller
{
    /**
     * Banner sliders from frontend builder (banner.element).
     */
    public function index(): JsonResponse
    {
        $templateName = activeTemplateName();
        $cacheKey = "api_sliders_{$templateName}";

        $sliders = Cache::remember($cacheKey, 300, function () use ($templateName) {
            return \App\Models\Frontend::where('tempname', $templateName)
                ->where('data_keys', 'banner.element')
                ->orderBy('id')
                ->get();
        });

        $items = $sliders->map(function ($slider) {
            $dv = $slider->data_values ?? (object) [];
            $imageName = $dv->slider ?? null;
            $link = $dv->link ?? null;
            $imageUrl = $imageName
                ? asset('assets/images/frontend/banner/' . $imageName)
                : null;
            return [
                'id' => $slider->id,
                'image_url' => $imageUrl,
                'link' => $link,
            ];
        })->values()->all();

        return response()->json([
            'remark' => 'sliders_list',
            'status' => 'success',
            'message' => ['success' => ['Sliders retrieved.']],
            'data' => ['sliders' => $items],
        ]);
    }
}
