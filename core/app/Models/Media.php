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

    function getFullUrlAttribute() {
        return getImage($this->path . '/' . $this->file_name);
    }

    function getThumbUrlAttribute() {
        $thumbPath = $this->path . '/thumb_' . $this->file_name;
        if (Storage::disk('public')->exists($thumbPath)) {
            return getImage($thumbPath);
        }
        return $this->full_url;
    }
}
