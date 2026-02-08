<div class="modal custom--modal fade" id="loginAndGuestModal" tabindex="-1" role="dialog" aria-labelledby="loginGuestModalTitle" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content login-guest-modal">
            <div class="modal-header login-guest-modal__header">
                <h5 class="modal-title" id="loginGuestModalTitle">@lang('Login or Continue as Guest')</h5>
                <button type="button" class="modal-close-btn" data-bs-dismiss="modal" aria-label="@lang('Close')">
                    <i class="las la-times"></i>
                </button>
            </div>
            <div class="modal-body login-guest-modal__body">
                <ul class="nav nav-tabs login-guest-tabs" id="loginGuestTabs" role="tablist">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active" id="guest-tab" data-bs-toggle="tab" data-bs-target="#guest" type="button" role="tab" aria-controls="guest" aria-selected="true">
                            @lang('Checkout Without Login')
                        </button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link" id="login-tab" data-bs-toggle="tab" data-bs-target="#login" type="button" role="tab" aria-controls="login" aria-selected="false">
                            @lang('Continue with Login')
                        </button>
                    </li>
                </ul>
                <div class="tab-content login-guest-tab-content" id="loginGuestTabContent">
                    <div class="tab-pane fade" id="login" role="tabpanel" aria-labelledby="login-tab">
                        @include('Template::partials.login', ['idPrefix' => 'auth-user'])
                    </div>
                    @php
                        $guestUser = session('guest_user_data');
                        if ($guestUser && $guestUser->country_code) {
                            $mobileCode = $guestUser->country_code;
                        } else {
                            $info = json_decode(json_encode(getIpInfo()), true);
                            $mobileCode = @implode(',', $info['code']);
                        }
                        $countries = getCountries();
                        $checkoutContent = getContent('guest_checkout.content', true)?->data_values;
                    @endphp
                    <div class="tab-pane fade show active" id="guest" role="tabpanel" aria-labelledby="guest-tab">
                        @if (@$checkoutContent->description_in_checkout_form)
                            <h5 class="login-guest-modal__section-title">@lang('Billing details')</h5>
                        @endif
                        <form action="{{ route('checkout.guest.info.store') }}" method="POST" class="login-guest-form">
                            @csrf
                            <div class="form-group">
                                <label class="form--label" for="guest-email">@lang('Enter your email address')</label>
                                <input type="email" value="{{ @$guestUser->email }}" class="form-control form--control" id="guest-email" name="email" required placeholder="@lang('your@email.com')">
                            </div>
                            <input type="hidden" name="mobile_code">
                            <input type="hidden" name="country_code">
                            <div class="form-group">
                                <label class="form--label" for="guest-mobile">@lang('Your WhatsApp Number')</label>
                                <div class="input-group">
                                    <input type="tel" name="mobile" value="{{ @$guestUser->mobile }}" class="form-control form--control" id="guest-mobile" required placeholder="@lang('Phone number')">
                                </div>
                            </div>
                            <button type="submit" class="btn btn--base w-100 h-45">@lang('Proceed as Guest')</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

@push('style-lib')
    <link rel="stylesheet" href="{{ asset('assets/global/css/select2.min.css') }}">
@endpush

@push('script-lib')
    <script src="{{ asset('assets/global/js/select2.min.js') }}"></script>
@endpush

@push('script')
    <script>
        "use strict";
        (function($) {
            const formatSelection = (state) => {
                if (!state.id) {
                    return state.text;
                }
                return `+${state.element.dataset.mobile_code}`;
            }

            @if ($mobileCode)
                const selectedCountry = $(`[data-code={{ $mobileCode }}]`).val();
            @else
                const selectedCountry = $('select[name=country] option').first().val();
            @endif

            $('#loginAndGuestModal select[name=country]').val(selectedCountry).select2({
                dropdownParent: $('#loginAndGuestModal select[name=country]').parent(),
                templateSelection: formatSelection
            });

            $('#loginAndGuestModal select[name=country]').on('change', function() {
                $('input[name=mobile_code]').val($('select[name=country] :selected').last().data('mobile_code'));
                $('input[name=country_code]').val($('select[name=country] :selected').last().data('code'));
                $('.mobile-code').text('+' + $('select[name=country] :selected').last().data('mobile_code'));
            });

            $('input[name=mobile_code]').val($('select[name=country] :selected').data('mobile_code'));
            $('input[name=country_code]').val($('select[name=country] :selected').data('code'));
            $('.mobile-code').text('+' + $('select[name=country] :selected').data('mobile_code'));
        })(jQuery);
    </script>
@endpush
