@extends('admin.layouts.app')

@section('panel')
    <div class="row">
        <div class="col-lg-12">
            <div class="card b-radius--10 mb-3">
                <div class="card-body">
                    <div class="d-flex flex-wrap align-items-center justify-content-between gap-2">
                        <h6 class="mb-0">
                            @lang('Order'): <a href="{{ route('admin.order.details', $conversation->order_id) }}">#{{ $conversation->order->order_number }}</a>
                            @if ($conversation->user_id)
                                | @lang('Customer'): <a href="{{ route('admin.users.detail', $conversation->user_id) }}">{{ $conversation->user->username ?? $conversation->user->email }}</a>
                            @endif
                        </h6>
                        <a href="{{ route('admin.order.conversation.index') }}" class="btn btn-outline--dark btn-sm">
                            <i class="las la-arrow-left"></i> @lang('Back to list')
                        </a>
                    </div>
                </div>
            </div>

            <div class="card b-radius--10">
                <div class="card-body">
                    <div class="conversation-messages mb-4 p-3 bg-light rounded" style="max-height: 400px; overflow-y: auto;">
                        @forelse ($messages as $msg)
                            <div class="mb-3 d-flex {{ $msg->isFromAdmin() ? 'justify-content-end' : 'justify-content-start' }}">
                                <div class="rounded px-3 py-2 shadow-sm {{ $msg->isFromAdmin() ? 'bg-primary text-white' : 'bg-white border' }}" style="max-width: 85%;">
                                    @if ($msg->isFromUser())
                                        <small class="d-block opacity-75 mb-1">@lang('Customer')</small>
                                    @else
                                        <small class="d-block opacity-75 mb-1">@lang('You')</small>
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
                                            <a href="{{ route('admin.order.conversation.attachment', $msg->id) }}" class="small d-inline-flex align-items-center gap-1 mt-1 {{ $msg->isFromAdmin() ? 'text-white' : '' }}">
                                                <i class="las la-paperclip"></i> {{ $msg->attachment_name }}
                                            </a>
                                        </div>
                                    @endif
                                    <small class="opacity-75">{{ $msg->created_at->format('M j, H:i') }}</small>
                                </div>
                            </div>
                        @empty
                            <p class="text-center text-muted mb-0">@lang('No messages yet.')</p>
                        @endforelse
                    </div>

                    <form action="{{ route('admin.order.conversation.reply', $conversation->id) }}" method="post" enctype="multipart/form-data">
                        @csrf
                        <div class="form-group mb-2">
                            <textarea name="message" class="form-control" rows="3" placeholder="@lang('Type your reply...')" maxlength="5000">{{ old('message') }}</textarea>
                            @error('message')
                                <small class="text-danger">{{ $message }}</small>
                            @enderror
                        </div>
                        <div class="d-flex flex-wrap align-items-center gap-2">
                            <label class="mb-0 btn btn-outline--dark btn-sm">
                                <i class="las la-paperclip"></i> @lang('Attach file')
                                <input type="file" name="attachment" class="d-none" accept=".jpg,.jpeg,.png,.gif,.webp,.pdf,.doc,.docx,.xls,.xlsx,.txt,.zip">
                            </label>
                            <span class="small text-muted" id="attachment-name"></span>
                            <button type="submit" class="btn btn--primary btn-sm">
                                <i class="las la-paper-plane"></i> @lang('Send Reply')
                            </button>
                        </div>
                        <small class="text-muted d-block mt-1">@lang('Allowed: images, PDF, Word, Excel, text, ZIP. Max 10MB.')</small>
                        @error('attachment')
                            <small class="text-danger d-block">{{ $message }}</small>
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
