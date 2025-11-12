<?php

namespace App\Http\Helpers;

use Illuminate\Support\Facades\Cache;
use Spatie\ImageOptimizer\OptimizerChainFactory;

class ImageHelper
{
    public static function optimize($relativePath)
    {
        $fullPath = public_path($relativePath);
        $cacheKey = 'optimized_image_' . md5($fullPath . filemtime($fullPath));

        // Check cache first
        if (Cache::has($cacheKey)) {
            return Cache::get($cacheKey);
        }

        // Optimize and store in /storage/optimized/
        $optimizedDir = storage_path('app/public/optimized/');
        if (!is_dir($optimizedDir)) {
            mkdir($optimizedDir, 0777, true);
        }

        $optimizedPath = $optimizedDir . basename($relativePath);

        $optimizer = OptimizerChainFactory::create();
        $optimizer->optimize($fullPath, $optimizedPath);

        // Cache for 30 days
        $optimizedUrl = asset('storage/optimized/' . basename($relativePath));
        Cache::put($cacheKey, $optimizedUrl, now()->addDays(30));

        return $optimizedUrl;
    }
}
