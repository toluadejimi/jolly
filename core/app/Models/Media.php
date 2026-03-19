<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Media extends Model {

    protected $appends = ['full_url', 'thumb_url'];

    public function productImages() {
        return  $this->belongsToMany(Product::class);
    }

    public function productVariantImages() {
        return  $this->belongsToMany(ProductVariant::class);
    }

    function products() {
        return $this->hasMany(Product::class, 'main_image_id');
    }

    function productVariants() {
        return $this->hasMany(ProductVariant::class, 'main_image_id');
    }

    function categories() {
        return $this->hasMany(Category::class);
    }

    function brands() {
        return $this->hasMany(Brand::class);
    }

    /**
     * Full URL for the image. Files are under storage/app/public/{path}, exposed at /storage/{path}.
     */
    function getFullUrlAttribute() {
        $relative = ltrim($this->path . '/' . $this->file_name, '/');
        if (Storage::disk('public')->exists($relative)) {
            return asset('storage/' . $relative);
        }
        return asset($this->path . '/' . $this->file_name);
    }

    /**
     * Thumbnail URL. Prefer thumb_ file in storage, else full image.
     */
    function getThumbUrlAttribute() {
        $thumbRelative = ltrim($this->path . '/thumb_' . $this->file_name, '/');
        if (Storage::disk('public')->exists($thumbRelative)) {
            return asset('storage/' . $thumbRelative);
        }
        return $this->full_url;
    }
}
