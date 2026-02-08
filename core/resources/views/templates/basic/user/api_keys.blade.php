@extends('Template::layouts.user')

@section('panel')
    <div class="row gy-4">
        <div class="col-12">
            <div class="card custom--card">
                <div class="card-body">
                    <h5 class="title mb-3">@lang('Generate API Key')</h5>
                    <p class="text-muted small mb-3">@lang('Use API keys to connect your applications and place orders programmatically. Keep your key secret.')</p>
                    <form method="POST" action="{{ route('user.api.keys.store') }}" class="row g-3 align-items-end">
                        @csrf
                        <div class="col-md-6">
                            <label class="form-label">@lang('Key name (optional)')</label>
                            <input type="text" class="form-control form--control" name="name" value="{{ old('name') }}" placeholder="@lang('e.g. My App')" maxlength="100">
                        </div>
                        <div class="col-md-6">
                            <button type="submit" class="btn btn--base">@lang('Generate new key')</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        <div class="col-12">
            <div class="card custom--card">
                <div class="card-body">
                    <h5 class="title mb-3">@lang('Your API Keys')</h5>
                    @if ($keys->isEmpty())
                        <p class="text-muted mb-0">@lang('No API keys yet. Generate one above.')</p>
                    @else
                        <div class="table-responsive">
                            <table class="table table--responsive--md">
                                <thead>
                                    <tr>
                                        <th>@lang('Name')</th>
                                        <th>@lang('Key (prefix)')</th>
                                        <th>@lang('Last used')</th>
                                        <th>@lang('Created')</th>
                                        <th>@lang('Action')</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($keys as $key)
                                        <tr>
                                            <td>{{ $key->name ?: '—' }}</td>
                                            <td><code class="text-muted">{{ $key->key_prefix }}…</code></td>
                                            <td>{{ $key->last_used_at ? $key->last_used_at->diffForHumans() : '—' }}</td>
                                            <td>{{ $key->created_at->format('M d, Y') }}</td>
                                            <td>
                                                <form method="POST" action="{{ route('user.api.keys.destroy', $key->id) }}" class="d-inline" onsubmit="return confirm('@lang('Revoke this key? It will stop working immediately.')');">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button type="submit" class="btn btn-sm btn--danger">@lang('Revoke')</button>
                                                </form>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    @endif
                </div>
            </div>
        </div>
        <div class="col-12">
            <div class="card custom--card">
                <div class="card-body">
                    <h6 class="title mb-2">@lang('How to use')</h6>
                    <p class="small text-muted mb-0">@lang('Send your API key in every request:') <code>X-API-Key: your_key</code> @lang('or') <code>Authorization: Bearer your_key</code>. @lang('See') <a href="{{ route('api.documentation') }}">@lang('API documentation')</a> @lang('for endpoints and examples.')</p>
                </div>
            </div>
        </div>
    </div>

    @if (session('new_key_plain'))
        <div class="modal fade show d-block" id="newKeyModal" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">@lang('Your new API key')</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <p class="text-danger small">@lang('Copy this key now. You will not see it again.')</p>
                        <div class="input-group">
                            <input type="text" class="form-control form--control font-monospace" id="newKeyInput" value="{{ session('new_key_plain') }}" readonly>
                            <button type="button" class="btn btn--base" onclick="navigator.clipboard.writeText(document.getElementById('newKeyInput').value); this.textContent='@lang('Copied!')';">@lang('Copy')</button>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn--base" data-bs-dismiss="modal">@lang('Done')</button>
                    </div>
                </div>
            </div>
        </div>
    @endif
@endsection
