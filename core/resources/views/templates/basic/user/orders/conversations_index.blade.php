@extends('Template::layouts.user')

@section('panel')
    <div class="mb-4 d-flex align-items-center justify-content-between flex-wrap gap-2">
        <h5 class="mb-0">@lang('Contact Seller')</h5>
        <a href="{{ route('user.orders.all') }}" class="btn btn-outline--primary btn-sm">
            <i class="las la-arrow-left"></i> @lang('Back to Orders')
        </a>
    </div>

    <div class="conversations-list">
        @forelse ($conversations as $conv)
            @php
                $order = $conv->order;
                $lastMsg = $conv->messages->first();
            @endphp
            <a href="{{ route('user.orders.conversation.show', $order->order_number) }}" class="conversation-card d-block rounded-3 border mb-3 p-3 text-decoration-none text-body">
                <div class="d-flex justify-content-between align-items-start flex-wrap gap-2">
                    <div>
                        <span class="badge bg-primary opacity-75 me-2">#{{ $order->order_number }}</span>
                        <strong>@lang('Order')</strong>
                    </div>
                    <small class="text-muted">{{ $conv->updated_at->diffForHumans() }}</small>
                </div>
                @if ($lastMsg)
                    <p class="mb-0 mt-2 text-muted small text-truncate" style="max-width: 100%;">
                        {{ $lastMsg->message ? Str::limit($lastMsg->message, 60) : ($lastMsg->attachment_name ? __('Attachment') : '—') }}
                    </p>
                @else
                    <p class="mb-0 mt-2 text-muted small">@lang('No messages yet')</p>
                @endif
            </a>
        @empty
            <div class="text-center py-5 text-muted">
                <i class="las la-comments fa-3x mb-3 opacity-50"></i>
                <p class="mb-0">@lang('No conversations yet.')</p>
                <p class="small">@lang('Open an order and use "Contact seller" to start a chat.')</p>
                <a href="{{ route('user.orders.all') }}" class="btn btn--primary btn-sm mt-2">@lang('View Orders')</a>
            </div>
        @endforelse
    </div>

    @if ($conversations->hasPages())
        <div class="mt-4">
            {{ paginateLinks($conversations) }}
        </div>
    @endif
@endsection
