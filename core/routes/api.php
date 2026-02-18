<?php

use Illuminate\Support\Facades\Route;

Route::middleware(['throttle:60,1'])->group(function () {
    Route::post('login', [App\Http\Controllers\Api\AuthController::class, 'login'])->name('auth.login');
    Route::post('register', [App\Http\Controllers\Api\AuthController::class, 'register'])->name('auth.register');

    Route::get('categories', [App\Http\Controllers\Api\CategoryController::class, 'index'])->name('categories.index');
    Route::get('sliders', [App\Http\Controllers\Api\SliderController::class, 'index'])->name('sliders.index');
    Route::get('products', [App\Http\Controllers\Api\ProductController::class, 'index'])->name('products.index');
    Route::get('products/{id}', [App\Http\Controllers\Api\ProductController::class, 'show'])->name('products.show');
    Route::get('order-tracking/{orderNumber}', [App\Http\Controllers\Api\OrderTrackingController::class, 'show'])->name('order.tracking');

    Route::middleware('api.key')->group(function () {
        Route::post('change-password', [App\Http\Controllers\Api\AuthController::class, 'changePassword'])->name('auth.change_password');
        Route::get('dashboard', [App\Http\Controllers\Api\DashboardController::class, 'index'])->name('dashboard');
        Route::get('shipping-methods', [App\Http\Controllers\Api\ShippingController::class, 'index'])->name('shipping.methods');
        Route::get('payment-methods', [App\Http\Controllers\Api\PaymentController::class, 'methods'])->name('payment.methods');
        Route::get('orders', [App\Http\Controllers\Api\OrderController::class, 'index'])->name('orders.index');
        Route::get('orders/{order}', [App\Http\Controllers\Api\OrderController::class, 'show'])->name('orders.show');
        Route::post('upload-customer-photos', [App\Http\Controllers\Api\OrderController::class, 'uploadCustomerPhotos'])->name('orders.upload_photos');
        Route::post('orders', [App\Http\Controllers\Api\OrderController::class, 'store'])->name('orders.store');
        Route::post('payment/initiate', [App\Http\Controllers\Api\PaymentController::class, 'initiate'])->name('payment.initiate');
    });
});
