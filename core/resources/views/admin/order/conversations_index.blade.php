@extends('admin.layouts.app')

@section('panel')
    <div class="row">
        <div class="col-lg-12">
            <div class="card b-radius--10">
                <div class="card-body p-0">
                    <div class="table-responsive--md table-responsive">
                        <table class="table table--light style--two">
                            <thead>
                                <tr>
                                    <th>@lang('Order')</th>
                                    <th>@lang('Customer')</th>
                                    <th>@lang('Last message')</th>
                                    <th>@lang('Updated')</th>
                                    <th>@lang('Action')</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($conversations as $conv)
                                    @php
                                        $lastMsg = $conv->messages->first();
                                        $unread = $conv->unreadCountForAdmin() > 0;
                                    @endphp
                                    <tr class="{{ $unread ? 'table-warning' : '' }}">
                                        <td>
                                            <a href="{{ route('admin.order.details', $conv->order_id) }}">#{{ $conv->order->order_number }}</a>
                                        </td>
                                        <td>
                                            @if ($conv->user_id)
                                                <a href="{{ route('admin.users.detail', $conv->user_id) }}">{{ $conv->user->username ?? $conv->user->email }}</a>
                                            @else
                                                —
                                            @endif
                                        </td>
                                        <td>
                                            @if ($lastMsg)
                                                {{ $lastMsg->message ? Str::limit($lastMsg->message, 50) : ($lastMsg->attachment_name ? __('Attachment') : '—') }}
                                            @else
                                                <span class="text-muted">@lang('No messages')</span>
                                            @endif
                                        </td>
                                        <td>{{ $conv->updated_at->diffForHumans() }}</td>
                                        <td>
                                            <a href="{{ route('admin.order.conversation.show', $conv->id) }}" class="btn btn-outline--primary btn-sm">
                                                <i class="las la-comments"></i> @lang('View / Reply')
                                            </a>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td class="text-center text-muted" colspan="5">@lang('No conversations yet.')</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
                @if ($conversations->hasPages())
                    <div class="card-footer">
                        {{ $conversations->links() }}
                    </div>
                @endif
            </div>
        </div>
    </div>
@endsection
