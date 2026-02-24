@extends('admin.layouts.app')

@section('panel')
    <div class="row">
        <div class="col-lg-12">
            {{-- Header --}}
            <div class="card b-radius--10 border-0 shadow-sm mb-4">
                <div class="card-body">
                    <div class="d-flex flex-wrap align-items-center justify-content-between gap-3">
                        <div class="d-flex flex-wrap align-items-center gap-3">
                            <a href="{{ route('admin.order.conversation.index') }}" class="btn btn-outline--dark btn-sm">
                                <i class="las la-arrow-left"></i>
                            </a>
                            <div>
                                <h6 class="mb-0">
                                    @lang('Conversation')
                                    <a href="{{ route('admin.order.details', $conversation->order_id) }}" class="text-primary text-decoration-none ms-1">
                                        #{{ $conversation->order->order_number }}
                                    </a>
                                </h6>
                                <small class="text-muted">
                                    @if ($conversation->user_id)
                                        @lang('Customer'): <a href="{{ route('admin.users.detail', $conversation->user_id) }}" class="text-decoration-none">{{ $conversation->user->username ?? $conversation->user->email }}</a>
                                    @else
                                        @lang('Guest order')
                                    @endif
                                    · {{ $conversation->updated_at->diffForHumans() }}
                                </small>
                            </div>
                        </div>
                        <a href="{{ route('admin.order.details', $conversation->order_id) }}" class="btn btn--primary btn-sm">
                            <i class="las la-external-link-alt"></i> @lang('Order details')
                        </a>
                    </div>
                </div>
            </div>

            {{-- Messages --}}
            <div class="card b-radius--10 border-0 shadow-sm mb-4">
                <div class="card-header bg--light border-0 py-3">
                    <h6 class="mb-0">@lang('Messages')</h6>
                </div>
                <div class="card-body p-4">
                    <div class="conversation-messages rounded-3" style="max-height: 420px; overflow-y: auto; background: var(--bs-body-bg, #f8f9fa);">
                        @forelse ($messages as $msg)
                            <div class="d-flex mb-4 {{ $msg->isFromAdmin() ? 'justify-content-end' : 'justify-content-start' }}">
                                <div class="d-flex flex-column {{ $msg->isFromAdmin() ? 'align-items-end' : 'align-items-start' }}" style="max-width: 85%;">
                                    <div class="rounded-3 px-3 py-2 shadow-sm {{ $msg->isFromAdmin() ? 'bg-primary text-white' : 'bg-white border' }}">
                                        <div class="d-flex align-items-center gap-2 mb-1">
                                            @if ($msg->isFromUser())
                                                <i class="las la-user text-muted small"></i>
                                                <small class="fw-semibold opacity-75">@lang('Customer')</small>
                                            @else
                                                <i class="las la-headset text-white small opacity-75"></i>
                                                <small class="opacity-75">@lang('You')</small>
                                            @endif
                                            <small class="opacity-75 ms-auto">{{ $msg->created_at->format('M j, H:i') }}</small>
                                        </div>
                                        @if ($msg->message)
                                            <div class="mb-1">{!! nl2br(e($msg->message)) !!}</div>
                                        @endif
                                        @if ($msg->attachment_path)
                                            @php
                                                $ext = strtolower(pathinfo($msg->attachment_name, PATHINFO_EXTENSION));
                                                $isImage = in_array($ext, ['jpg','jpeg','png','gif','webp']);
                                            @endphp
                                            <div class="attachment-wrap mt-2">
                                                @if ($isImage)
                                                    <a href="{{ asset($msg->attachment_path) }}" target="_blank" rel="noopener" class="d-inline-block">
                                                        <img src="{{ asset($msg->attachment_path) }}" alt="" class="rounded img-thumbnail" style="max-height: 140px;">
                                                    </a>
                                                @endif
                                                <a href="{{ route('admin.order.conversation.attachment', $msg->id) }}" class="small d-inline-flex align-items-center gap-1 mt-1 {{ $msg->isFromAdmin() ? 'text-white' : 'text-primary' }}">
                                                    <i class="las la-paperclip"></i> {{ $msg->attachment_name }}
                                                </a>
                                            </div>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        @empty
                            <div class="text-center py-5 text-muted">
                                <i class="las la-comment-dots fa-3x mb-3 opacity-50"></i>
                                <p class="mb-0">@lang('No messages yet.')</p>
                                <p class="small">@lang('Type your reply below and send.')</p>
                            </div>
                        @endforelse
                    </div>
                </div>
            </div>

            {{-- Reply form --}}
            <div class="card b-radius--10 border-0 shadow-sm">
                <div class="card-header bg--light border-0 py-3">
                    <h6 class="mb-0">@lang('Send reply')</h6>
                </div>
                <div class="card-body">
                    <form action="{{ route('admin.order.conversation.reply', $conversation->id) }}" method="post" enctype="multipart/form-data">
                        @csrf
                        <div class="mb-3">
                            <label class="form-label">@lang('Message')</label>
                            <textarea name="message" class="form-control" rows="3" placeholder="@lang('Type your reply...')" maxlength="5000">{{ old('message') }}</textarea>
                            @error('message')
                                <small class="text-danger">{{ $message }}</small>
                            @enderror
                        </div>
                        <div class="d-flex flex-wrap align-items-center gap-3">
                            <label class="btn btn-outline--dark btn-sm mb-0">
                                <i class="las la-paperclip"></i> @lang('Attach file')
                                <input type="file" name="attachment" class="d-none" accept=".jpg,.jpeg,.png,.gif,.webp,.pdf,.doc,.docx,.xls,.xlsx,.txt,.zip">
                            </label>
                            <span class="small text-muted" id="attachment-name"></span>
                            <button type="submit" class="btn btn--primary">
                                <i class="las la-paper-plane"></i> @lang('Send Reply')
                            </button>
                        </div>
                        <small class="text-muted d-block mt-2">@lang('Allowed: images, PDF, Word, Excel, text, ZIP. Max 10MB.')</small>
                        @error('attachment')
                            <small class="text-danger d-block mt-1">{{ $message }}</small>
                        @enderror
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('script')
<script>
(function () {
    var fileInput = document.querySelector('input[name="attachment"]');
    var nameEl = document.getElementById('attachment-name');
    if (fileInput && nameEl) {
        fileInput.addEventListener('change', function () {
            nameEl.textContent = this.files.length ? this.files[0].name : '';
        });
    }
})();
</script>
@endpush

@push('style')
<style>
.conversation-messages::-webkit-scrollbar { width: 8px; }
.conversation-messages::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 4px; }
.conversation-messages::-webkit-scrollbar-thumb { background: #c1c1c1; border-radius: 4px; }
.conversation-messages::-webkit-scrollbar-thumb:hover { background: #a8a8a8; }
</style>
@endpush
