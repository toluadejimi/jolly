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

                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Receiver's First Name</label>
                                <input type="text" class="form-control form--control" name="firstname" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Receiver Last Name</label>
                                <input type="text" class="form-control form--control" name="lastname" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Receiver's Mobile (Whatsapp)</label>
                                <input type="text" class="form-control form--control" name="mobile" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Receiver's Email</label>
                                <input type="text" class="form-control form--control" name="email" required>
                            </div>
                        </div>

                        <div class="row mt-4">



                            <div class="col-md-4">
                                <div class="form-group">
                                    <label class="form-label">Receiver's Country</label>
                                    <select name="country" class="form-control form--control select2" required>
                                        <option value="">Search Country...</option>
                                        @foreach ($countries as $key => $country)
                                            <option data-mobile_code="{{ $country->dial_code }}"
                                                    value="{{ $country->country }}"
                                                    data-code="{{ $key }}">
                                                {{ __($country->country) }}
                                            </option>
                                        @endforeach
                                    </select>




                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group">
                                    <label>Receiver's State</label>

                                    <div id="stateInputWrapper">
                                        <input type="text"
                                               value="{{ @$shippingInformation->state }}"
                                               class="form-control form--control"
                                               name="state"
                                               id="stateInput"
                                               required>
                                    </div>
                                </div>


                            </div>

                            <div class="col-md-4">
                                <div class="form-group">
                                    <label>Receiver's City</label>
                                    <input type="text" value="{{ @$shippingInformation->city }}" class="form-control form--control"
                                           name="city" required>
                                </div>
                            </div>

                            <hr>

                            <div class="col-md-3">
                                <div class="form-group">
                                    <label>@lang('House number, Apartment, suite, unit, flat etc')</label>
                                    <input type="text" value="{{ @$shippingInformation->city }}" class="form-control form--control"
                                           name="apt">
                                </div>
                            </div>

                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>Receiver's Street Address</label>
                                    <input type="text" value="{{ @$shippingInformation->address }}"
                                           class="form-control form--control" name="address" required>
                                </div>
                            </div>

                            <div class="col-md-3">
                                <div class="form-group">
                                    <label>Receiver's Zip</label>
                                    <input type="text" value="{{ @$shippingInformation->zip }}" class="form-control form--control"
                                           name="zip" required>
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
    <!-- jQuery must load FIRST -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

    <!-- Select2 -->
    <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

    <script>
        $(document).ready(function () {

            /** ---------------------------------------------------
             * 1. Initialize Country Select2
             * --------------------------------------------------- */
            $("select[name='country']").select2({
                placeholder: "Search Country...",
                allowClear: true,
                width: '100%',
                dropdownParent: $('#addressModal')
            });


            /** ---------------------------------------------------
             * 2. Load States JSON Files (USA + Canada)
             * --------------------------------------------------- */
            let usaStates = {};
            let canadaStates = {};

            $.getJSON("{{ asset('core/resources/views/partials/usastates.json') }}", function(data) {
                usaStates = data;
            });

            $.getJSON("{{ asset('core/resources/views/partials/castates.json') }}", function(data) {
                canadaStates = data;
            });


            /** ---------------------------------------------------
             * 3. Functions for input/select switching
             * --------------------------------------------------- */
            function loadStateSelect(states) {
                let selectHtml = `
                    <select name="state" id="stateSelect" class="form-control form--control select2" required>
                        <option value="">Select State</option>
                `;

                $.each(states, function(key, value) {
                    selectHtml += `<option value="${value}">${value}</option>`;
                });

                selectHtml += `</select>`;

                $("#stateInputWrapper").html(selectHtml);

                // initialize Select2 for states with modal parent
                $("#stateSelect").select2({
                    width: '100%',
                    dropdownParent: $('#addressModal') // FIX
                });
            }

            function loadStateInput() {
                $("#stateInputWrapper").html(`
                    <input type="text" class="form-control form--control" name="state" required>
                `);
            }

            /** ---------------------------------------------------
             * 4. Country change event
             * --------------------------------------------------- */
            $("select[name='country']").on("change", function () {
                const selectedCountry = $(this).find(":selected").data("code");

                if (selectedCountry === "US") {
                    loadStateSelect(usaStates);
                } else if (selectedCountry === "CA") {
                    loadStateSelect(canadaStates);
                } else {
                    loadStateInput();
                }
            });

            $("select[name='country']").trigger("change");
        });
    </script>

    <!-- MODAL SCRIPT (Not related to Select2) -->
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
                modal.find('.modal-title').text(`@lang('Update Receiver Address')`);
                let address = $(this).data('resource');

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
