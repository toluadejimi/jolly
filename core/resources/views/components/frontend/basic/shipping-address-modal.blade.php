@props(['countries' => []])

<div class="modal custom--modal fade" id="addressModal" role="dialog">
    <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-body">
                <h5 class="modal-title"></h5>
                <button type="button" class="close modal-close-btn" data-bs-dismiss="modal" aria-label="Close">
                    <i class="las la-times"></i>
                </button>

                <form method="POST" action="">
                    @csrf

                    <div class="row">

                        <div class="col-md-12">
                            <div class="form-group">
                                <label>@lang('Title')</label>
                                <input type="text" class="form-control form--control" name="label" required>
                            </div>
                        </div>

                        <div class="col-md-12">
                            <div class="form-group">
                                <label class="form-label">Country / Region</label>
                                <select name="country" class="form-control form--control select2" required>
                                    <option value="">Search Country...</option>

                                    @foreach ($countries as $key => $country)
                                        <option value="{{ $country->country }}"
                                                data-mobile_code="{{ $country->dial_code }}"
                                                data-code="{{ $key }}">
                                            {{ __($country->country) }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Receiver's First name</label>
                                <input type="text" class="form-control form--control" name="firstname" required>
                            </div>
                        </div>

                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Receiver's Last name</label>
                                <input type="text" value="{{ @$shippingInformation->lastname }}"
                                       class="form-control form--control" name="lastname" required>
                            </div>
                        </div>

                        <div class="col-md-12">
                            <div class="form-group">
                                <label>Street address</label>
                                <input type="text" value="{{ @$shippingInformation->address }}"
                                       class="form-control form--control"
                                       placeholder="House Number and Street Name"
                                       name="address" required>
                            </div>
                        </div>

                        <div class="col-md-12">
                            <div class="form-group">
                                <input type="text"
                                       value="{{ @$shippingInformation->apt }}"
                                       placeholder="House number, Apartment, Suite, Unit, etc"
                                       class="form-control form--control"
                                       name="apt">
                            </div>
                        </div>

                        <div class="col-md-12">
                            <div class="form-group">
                                <label>State / County</label>
                                <div id="stateInputWrapper">
                                    <input type="text"
                                           class="form-control form--control"
                                           name="state"
                                           id="stateInput"
                                           required>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-12">
                            <div class="form-group">
                                <label>Town / City</label>
                                <input type="text"
                                       value="{{ @$shippingInformation->city }}"
                                       class="form-control form--control"
                                       name="city"
                                       required>
                            </div>
                        </div>

                        <div class="col-md-12">
                            <div class="form-group">
                                <label>Postcode / ZIP</label>
                                <input type="text"
                                       value="{{ @$shippingInformation->zip }}"
                                       class="form-control form--control"
                                       name="zip"
                                       required>
                            </div>
                        </div>

                        <div class="col-md-12">
                            <div class="form-group">
                                <label>Receiver’s Phone Number ( Optional )</label>
                                <div class="input-group">
                                    <input type="number"
                                           name="mobile"
                                           value="{{ @$shippingInformation->mobile }}"
                                           class="form-control form--control">

                                    <input type="hidden" name="mobile_code" id="mobile_code" value="0">
                                    <input type="hidden" name="country_code" id="country_code" value="0">
                                    <input type="hidden" name="email" value="receiver@mail.com">
                                </div>
                            </div>
                        </div>

                    </div>

                    <div class="col-12 mt-3">
                        <button type="submit" class="btn btn--base w-100 h-45">@lang('Submit')</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

@push('script')

    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

    <!-- Select2 -->
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

    <script>
        $(document).ready(function () {

            const modal = $('#addressModal');
            const countrySelect = $("select[name='country']");

            /** Initialize Select2 safely */
            if (modal.length && countrySelect.length) {
                countrySelect.select2({
                    placeholder: "Search Country...",
                    allowClear: true,
                    width: '100%',
                    dropdownParent: modal
                });
            }

            /** Load USA & Canada states */
            let usaStates = {};
            let canadaStates = {};

            $.getJSON("{{ asset('core/resources/views/partials/usastates.json') }}", data => usaStates = data);
            $.getJSON("{{ asset('core/resources/views/partials/castates.json') }}", data => canadaStates = data);

            /** Replace input with select for US/Canada */
            function loadStateSelect(states) {
                let html = `<select name="state" id="stateSelect" class="form-control form--control select2" required>
                        <option value="">Select State</option>`;

                $.each(states, (i, v) => {
                    html += `<option value="${v}">${v}</option>`;
                });

                html += `</select>`;

                $("#stateInputWrapper").html(html);

                $("#stateSelect").select2({
                    width: '100%',
                    dropdownParent: modal
                });
            }

            function loadStateInput() {
                $("#stateInputWrapper").html(`
            <input type="text" class="form-control form--control" name="state" required>
        `);
            }

            /** Change event */
            countrySelect.on("change", function () {
                const code = $(this).find(":selected").data("code");

                if (code === "US") {
                    loadStateSelect(usaStates);
                } else if (code === "CA") {
                    loadStateSelect(canadaStates);
                } else {
                    loadStateInput();
                }
            });

            /** Trigger change */
            countrySelect.trigger("change");

        });
    </script>

    <script>
        (function($) {
            let modal = $('#addressModal');
            let action = `{{ route('user.shipping.address.store') }}`;

            $('.newAddress').on('click', function() {
                modal.find('.modal-title').text(`@lang('Add New Receiver Address')`);
                modal.find('form').attr('action', action);
                modal.modal('show');
            });

            $('.editAddress').on('click', function() {
                let address = $(this).data('resource');

                modal.find('.modal-title').text(`@lang('Update Receiver Address')`);
                modal.find('[name=firstname]').val(address.firstname);
                modal.find('[name=lastname]').val(address.lastname);
                modal.find('[name=mobile]').val(address.mobile);
                modal.find('[name=email]').val(address.email);
                modal.find('[name=city]').val(address.city);
                modal.find('[name=state]').val(address.state);
                modal.find('[name=zip]').val(address.zip);
                modal.find('[name=country]').val(address.country).trigger('change');
                modal.find('[name=address]').val(address.address);
                modal.find('[name=label]').val(address.label);

                modal.find('form').attr('action', `${action}/${address.id}`);
                modal.modal('show');
            });

            modal.on('hidden.bs.modal', function() {
                modal.find('form')[0].reset();
            });

        })(jQuery);
    </script>

@endpush
