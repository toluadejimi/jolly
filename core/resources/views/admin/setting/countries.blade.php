@extends('admin.layouts.app')

@section('panel')
    <div class="row">
        <div class="col-lg-12">
            <form method="post">
                @csrf
                <div class="card">
                    <div class="card-header d-flex flex-wrap gap-3 justify-content-between align-items-center">
                        <div>
                            <h6 class="mb-1">@lang('Country Dropdown Settings')</h6>
                            <p class="mb-0 text-muted">@lang('Only enabled countries will appear in customer country dropdowns.')</p>
                        </div>
                        <div class="d-flex flex-wrap gap-2">
                            <button type="submit" class="btn btn-sm btn-outline--dark" form="runMigrationsForm" onclick="return confirm('@lang('Run database migrations now?')')">
                                @lang('Run Migrations')
                            </button>
                            <button type="button" class="btn btn-sm btn-outline--primary selectAllCountries">@lang('Enable All')</button>
                            <button type="button" class="btn btn-sm btn-outline--danger deselectAllCountries">@lang('Disable All')</button>
                        </div>
                    </div>

                    <div class="card-body">
                        <div class="form-group position-relative mb-3">
                            <div class="country-search-icon"><i class="las la-search"></i></div>
                            <input class="form-control countrySearch" type="search" placeholder="@lang('Search country')...">
                        </div>

                        <div class="row gy-2 countryList">
                            @foreach ($countries as $code => $country)
                                <div class="col-xl-3 col-lg-4 col-sm-6 countryItem" data-country="{{ strtolower($code . ' ' . $country->country) }}">
                                    <label class="country-card mb-0">
                                        <input type="checkbox" name="country_codes[]" value="{{ $code }}" @checked(in_array($code, $enabledCountryCodes))>
                                        <span>
                                            <strong>{{ __($country->country) }}</strong>
                                            <small>{{ $code }} (+{{ $country->dial_code }})</small>
                                        </span>
                                    </label>
                                </div>
                            @endforeach
                        </div>
                    </div>

                    <div class="card-footer text-end">
                        <button type="submit" class="btn btn--primary">@lang('Save Changes')</button>
                    </div>
                </div>
            </form>

            <form id="runMigrationsForm" method="post" action="{{ route('admin.setting.countries.run.migrations') }}" class="d-none">
                @csrf
            </form>
        </div>
    </div>
@endsection

@push('style')
    <style>
        .country-search-icon {
            position: absolute;
            inset-inline-start: 0;
            top: 0;
            width: 42px;
            height: 100%;
            display: grid;
            place-items: center;
            color: #888;
        }

        .country-search-icon ~ .form-control {
            padding-left: 42px;
        }

        .country-card {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            height: 100%;
            padding: 12px;
            border: 1px solid #ebebeb;
            border-radius: 6px;
            cursor: pointer;
            background: #fff;
        }

        .country-card span {
            display: flex;
            flex-direction: column;
            gap: 2px;
            line-height: 1.25;
        }

        .country-card small {
            color: #777;
        }
    </style>
@endpush

@push('script')
    <script>
        (function($) {
            "use strict";

            $('.countrySearch').on('input', function() {
                const query = $(this).val().toLowerCase().trim();

                $('.countryItem').each(function() {
                    $(this).toggle($(this).data('country').includes(query));
                });
            });

            $('.selectAllCountries').on('click', function() {
                $('input[name="country_codes[]"]').prop('checked', true);
            });

            $('.deselectAllCountries').on('click', function() {
                $('input[name="country_codes[]"]').prop('checked', false);
            });
        })(jQuery);
    </script>
@endpush
