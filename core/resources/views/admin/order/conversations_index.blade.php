@extends('admin.layouts.app')

@section('panel')
    <div class="row">
        <div class="col-12">
            <div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-4">
                <div>
                    <h5 class="mb-1">@lang('Order Conversations')</h5>
                    <p class="text-muted small mb-0">@lang('View and reply to customer messages about their orders.')</p>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-12">
            <div class="card b-radius--10 border-0 shadow-sm">
                <div class="card-body p-0">
                    <div class="table-responsive--md table-responsive">
                        <table class="table table--light style--two table-hover align-middle mb-0">
                            <thead class="bg--light">
                                <tr>
                                    <th class="border-0 fw-semibold">@lang('Order')</th>
                                    <th class="border-0 fw-semibold">@lang('Customer')</th>
                                    <th class="border-0 fw-semibold">@lang('Last message')</th>
                                    <th class="border-0 fw-semibold">@lang('Updated')</th>
                                    <th class="border-0 fw-semibold text-end">@lang('Action')</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($conversations as $conv)
                                    @php
                                        $lastMsg = $conv->messages->first();
                                        $unread = $conv->unreadCountForAdmin() > 0;
                                    @endphp
                                    <tr class="{{ $unread ? 'table-warning bg-opacity-10' : '' }}">
                                        <td>
                                            <a href="{{ route('admin.order.details', $conv->order_id) }}" class="fw-semibold text-decoration-none">
                                                #{{ $conv->order->order_number }}
                                            </a>
                                            <br>
                                            <small class="text-muted">{{ showDateTime($conv->order->created_at, 'd M Y') }}</small>
                                        </td>
                                        <td>
                                            @if ($conv->user_id)
                                                <a href="{{ route('admin.users.detail', $conv->user_id) }}" class="text-decoration-none">
                                                    {{ $conv->user->username ?? $conv->user->email }}
                                                </a>
                                                @if ($unread)
                                                    <span class="badge bg-warning text-dark ms-1">{{ $conv->unreadCountForAdmin() }}</span>
                                                @endif
                                            @else
                                                <span class="text-muted">—</span>
                                            @endif
                                        </td>
                                        <td>
                                            @if ($lastMsg)
                                                <span class="text-dark">{{ $lastMsg->message ? Str::limit($lastMsg->message, 55) : ($lastMsg->attachment_name ? __('Attachment') . ': ' . Str::limit($lastMsg->attachment_name, 25) : '—') }}</span>
                                                <br>
                                                <small class="text-muted">{{ $lastMsg->created_at->diffForHumans() }}</small>
                                            @else
                                                <span class="text-muted fst-italic">@lang('No messages yet')</span>
                                            @endif
                                        </td>
                                        <td>
                                            <span class="text-muted">{{ $conv->updated_at->diffForHumans() }}</span>
                                        </td>
                                        <td class="text-end">
                                            <a href="{{ route('admin.order.conversation.show', $conv->id) }}" class="btn btn--primary btn-sm">
                                                <i class="las la-comments"></i> @lang('View / Reply')
                                            </a>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="5" class="text-center py-5">
                                            <i class="las la-comments fa-3x text-muted mb-3 d-block opacity-50"></i>
                                            <p class="text-muted mb-0">@lang('No conversations yet.')</p>
                                            <p class="small text-muted">@lang('Customers can start a chat from their order details.')</p>
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
                @if ($conversations->hasPages())
                    <div class="card-footer bg--light border-0 pt-0">
                        {{ $conversations->links() }}
                    </div>
                @endif
            </div>
        </div>
    </div>
@endsection
