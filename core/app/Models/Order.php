<?php

namespace App\Models;

use App\Constants\Status;
use App\Models\OrderConversation;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;

class Order extends Model {
    protected $guarded = ['id'];

    protected $casts = [
        'shipping_address' => 'object',
        'guest_user_info' => 'object',
        'estimated_delivery_at' => 'datetime',
        'estimated_delivery_end_at' => 'datetime',
    ];

    public function appliedCoupon() {
        return $this->hasOne(AppliedCoupon::class)->withTrashed();
    }

    public function user() {
        return $this->belongsTo(User::class);
    }

    public function guest() {
        return $this->belongsTo(Guest::class);
    }

    public function deposit() {
        return $this->hasOne(Deposit::class)->latest()->withDefault();
    }

    public function products() {
        return $this->belongsToMany(Product::class, 'order_details');
    }

    public function afterSaleDownloadableProducts() {
        return $this->belongsToMany(Product::class, 'order_details')->where('is_downloadable', Status::YES)->where('delivery_type', Status::DOWNLOAD_AFTER_SALE);
    }

    public function orderDetail() {
        return $this->hasMany(OrderDetail::class);
    }

    public function conversation() {
        return $this->hasOne(OrderConversation::class);
    }

    public function getAmountAttribute() {
        return $this->total_amount - $this->shipping_charge;
    }

    public function scopePending($query) {
        return $query->where('status', Status::ORDER_PENDING);
    }

    public function scopeProcessing($query) {
        return $query->where('status', Status::ORDER_PROCESSING);
    }

    public function scopeDispatched($query) {
        return $query->where('status', Status::ORDER_DISPATCHED);
    }

    public function scopeDelivered($query) {
        return $query->where('status', Status::ORDER_DELIVERED);
    }

    public function scopeCanceled($query) {
        return $query->where('status', Status::ORDER_CANCELED);
    }
    public function scopeReturned($query) {
        return $query->where('status', Status::ORDER_RETURNED);
    }

    public function scopeCod($query) {
        return $query->where('is_cod', Status::YES);
    }

    public function scopeIsValidOrder($query) {
        return $query->where(function ($query) {
            $query->where('payment_status', Status::YES)->orWhere('is_cod', Status::YES);
        });
    }

    public function scopeIsUnpaidOrder($query) {
        return $query->where(function ($query) {
            $query->where('payment_status', Status::NO);
        });
    }

    public function statusBadge() {
        if ($this->status == Status::ORDER_PENDING) {
            $class = 'warning';
            $text  = 'Pending';
        } elseif ($this->status == Status::ORDER_PROCESSING) {
            $class = 'primary';
            $text  = 'Processing';
        } elseif ($this->status == Status::ORDER_DISPATCHED) {
            $class = 'dark';
            $text  = 'Dispatched';
        } elseif ($this->status == Status::ORDER_DELIVERED) {
            $class = 'success';
            $text  = 'Delivered';
        } elseif ($this->status == Status::ORDER_CANCELED) {
            $class = 'danger';
            $text  = 'Cancelled';
        } elseif ($this->status == Status::ORDER_RETURNED) {
            $class = 'danger';
            $text  = 'Returned';
        }
        return "<span class='badge badge--$class'>" . trans($text) . "</span>";
    }

    public function paymentBadge() {
        if ($this->payment_status == Status::PAYMENT_SUCCESS) {
            return '<span class="badge badge--success">' . trans('Paid') . '</span>';
        } else {
            return '<span class="badge badge--danger">' . trans('Not Paid') . '</span>';
        }
    }

    public function initiatePayment($gate, $amount) {
        $charge   = $gate->fixed_charge + ($this->total_amount * $gate->percent_charge / 100);
        $payable  = $this->total_amount + $charge;

        $finalAmount = $payable * $gate->rate;

        $deposit                     = new Deposit();
        $deposit->user_id            = $this->user_id;
        $deposit->order_id           = $this->id;
        $deposit->method_code        = $gate->method_code;
        $deposit->method_currency    = strtoupper($gate->currency);
        $deposit->amount             = $amount;
        $deposit->charge             = $charge;
        $deposit->rate               = $gate->rate;
        $deposit->final_amount       = $finalAmount;

        $deposit->success_url = route("checkout.confirmation", $this->order_number);
        $deposit->failed_url  = route("checkout.payment.methods");

        $deposit->trx                = getTrx();
        $deposit->save();

        // Log payment initiation for debugging gateway reference/track matching (IPN).
        // This runs for both web and API flows because both call Order::initiatePayment().
        Log::warning(
            'Payment initiated (Deposit created): order_number=' . ($this->order_number ?? 'N/A') .
            ', order_id=' . ($this->id ?? 'N/A') .
            ', gateway_alias=' . ($gate->alias ?? 'unknown') .
            ', gateway_method_code=' . ($gate->method_code ?? 'N/A') .
            ', gateway_currency=' . ($gate->currency ?? 'N/A') .
            ', amount=' . ($amount ?? '0') .
            ', charge=' . ($charge ?? '0') .
            ', final_amount=' . ($finalAmount ?? '0') .
            ', trx=' . ($deposit->trx ?? 'N/A') .
            ', deposit_id=' . ($deposit->id ?? 'N/A') .
            ', customer_email=' . ($this->user?->email ?? $this->guest?->email ?? 'N/A')
        );

        return $deposit->trx;
    }

    public function hasPhysicalProduct($count = false) {
        $total = $this->products->where('is_downloadable', Status::NO)->count();
        if ($count) return $total;
        return $total > 0 ? true : false;
    }

    public function hasDownloadableProduct() {
        $total = $this->products->where('is_downloadable', Status::YES)->count();
        return $total > 0 ? true : false;
    }

    public function hasAfterSaleDownloadableProduct() {
        $total = $this->products->where('is_downloadable', Status::YES)->where('delivery_type', Status::DOWNLOAD_AFTER_SALE)->count();
        return $total > 0 ? true : false;
    }
}
