@extends('Template::layouts.user')

@section('panel')
    <div class="mb-4 d-flex align-items-center justify-content-between flex-wrap gap-2">
        <div>
            <a href="{{ route('user.orders.conversations.index') }}" class="btn btn-outline--light btn-sm me-2">
                <i class="las la-arrow-left"></i>
            </a>
            <span class="fw-semibold">@lang('Contact Seller')</span>
            <span class="badge bg-primary ms-2">#{{ $order->order_number }}</span>
        </div>
        <a href="{{ route('user.orders.details', $order->order_number) }}" class="btn btn-outline--primary btn-sm">
            @lang('Order details')
        </a>
    </div>

    <div class="conversation-box rounded-3 border bg-light overflow-hidden">
        <div class="conversation-messages p-3" style="max-height: 420px; overflow-y: auto;">
            @forelse ($messages as $msg)
                <div class="mb-3 d-flex {{ $msg->isFromUser() ? 'justify-content-end' : 'justify-content-start' }}">
                    <div class="message-bubble {{ $msg->isFromUser() ? 'user-msg' : 'admin-msg' }} rounded-3 px-3 py-2 shadow-sm" style="max-width: 85%;">
                        @if (!$msg->isFromUser())
                            <small class="d-block text-muted mb-1">@lang('Seller')</small>
                        @endif
                        @if ($msg->message)
                            <div class="mb-1">{!! nl2br(e($msg->message)) !!}</div>
                        @endif
                        @if ($msg->attachment_path)
                            @php
                                $ext = strtolower(pathinfo($msg->attachment_name, PATHINFO_EXTENSION));
                                $isImage = in_array($ext, ['jpg','jpeg','png','gif','webp']);
                            @endphp
                            <div class="attachment-wrap">
                                @if ($isImage)
                                    <a href="{{ asset($msg->attachment_path) }}" target="_blank" rel="noopener" class="d-inline-block">
                                        <img src="{{ asset($msg->attachment_path) }}" alt="" class="rounded img-thumbnail" style="max-height: 120px;">
                                    </a>
                                @endif
                                <a href="{{ route('user.orders.conversation.attachment', $msg->id) }}" class="small d-inline-flex align-items-center gap-1 mt-1">
                                    <i class="las la-paperclip"></i> {{ $msg->attachment_name }}
                                </a>
                            </div>
                        @endif
                        <small class="text-muted">{{ $msg->created_at->format('M j, H:i') }}</small>
                    </div>
                </div>
            @empty
                <p class="text-center text-muted py-4 mb-0">@lang('No messages yet. Send a message or attach a file below.')</p>
            @endforelse
        </div>

        <div class="conversation-form border-top bg-white p-3">
            <form action="{{ route('user.orders.conversation.store', $order->order_number) }}" method="post" enctype="multipart/form-data">
                @csrf
                <div class="mb-2">
                    <textarea name="message" class="form-control" rows="2" placeholder="@lang('Type your message...')" maxlength="5000">{{ old('message') }}</textarea>
                    @error('message')
                        <small class="text-danger">{{ $message }}</small>
                    @enderror
                </div>
                <div class="d-flex flex-wrap align-items-center gap-2">
                    <label class="mb-0 btn btn-outline--light btn-sm">
                        <i class="las la-paperclip"></i> @lang('Attach file')
                        <input type="file" name="attachment" class="d-none" accept=".jpg,.jpeg,.png,.gif,.webp,.pdf,.doc,.docx,.xls,.xlsx,.txt,.zip">
                    </label>
                    <span class="small text-muted" id="attachment-name"></span>
                    <button type="submit" class="btn btn--primary btn-sm ms-auto">
                        <i class="las la-paper-plane"></i> @lang('Send')
                    </button>
                </div>
                <small class="text-muted d-block mt-1">@lang('Allowed: images, PDF, Word, Excel, text, ZIP. Max 10MB.')</small>
                @error('attachment')
                    <small class="text-danger d-block">{{ $message }}</small>
                @enderror
            </form>
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
.message-bubble.user-msg { background: hsl(var(--base)); color: hsl(var(--white)); }
.message-bubble.admin-msg { background: #fff; }
.conversation-messages::-webkit-scrollbar { width: 6px; }
.conversation-messages::-webkit-scrollbar-thumb { background: #ccc; border-radius: 3px; }
</style>
@endpush
