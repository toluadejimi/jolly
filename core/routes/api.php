<?php

use Illuminate\Support\Facades\Route;

Route::middleware(['throttle:60,1'])->group(function () {
    Route::get('products', [App\Http\Controllers\Api\ProductController::class, 'index'])->name('products.index');
    Route::get('products/{id}', [App\Http\Controllers\Api\ProductController::class, 'show'])->name('products.show');
    Route::get('order-tracking/{orderNumber}', [App\Http\Controllers\Api\OrderTrackingController::class, 'show'])->name('order.tracking');

    Route::middleware('api.key')->group(function () {
        Route::get('payment-methods', [App\Http\Controllers\Api\PaymentController::class, 'methods'])->name('payment.methods');
        Route::get('orders', [App\Http\Controllers\Api\OrderController::class, 'index'])->name('orders.index');
        Route::get('orders/{order}', [App\Http\Controllers\Api\OrderController::class, 'show'])->name('orders.show');
        Route::post('orders', [App\Http\Controllers\Api\OrderController::class, 'store'])->name('orders.store');
        Route::post('payment/initiate', [App\Http\Controllers\Api\PaymentController::class, 'initiate'])->name('payment.initiate');
    });
});
