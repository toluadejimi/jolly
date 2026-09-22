<div class="card">
    <div class="card-header">
        <h6 class="card-title mb-0">@lang('Product Status')</h6>
    </div>
    <div class="card-body">
        <div class="form-group row">
            <div class="col-xl-12">
                <label>@lang('Publish Product')</label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="is_published" value="1" :checked="@$product->is_published == Status::YES" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('Show in Products Page')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="show_in_products_page" value="1" :checked="@$product->show_in_products_page" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('Today Delivery')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="today_delivery" value="1" :checked="@$product->today_delivery" />
            </div>
        </div>



        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('🇺🇸 US Express Shipping')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="usa_express_delivery" value="1" :checked="@$product->usa_express_delivery" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('🇺🇸 US Delivery')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="usa_delivery" value="1" :checked="@$product->usa_delivery" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('🌎 All Countries Delivery')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="all_countries_delivery" value="1" :checked="@$product->all_countries_delivery" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('Add Note')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="note" value="1" :checked="@$product->note" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('Same Day Bday & love letter')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="same_day_bday_love_letter" value="1" :checked="@$product->same_day_bday_love_letter" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('Front and Back Photo')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="customer_photo" value="1" :checked="@$product->customer_photo" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('Customised Text')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="customised_test" value="1" :checked="@$product->customised_test" />
            </div>
        </div>

        <div class="form-group row">
            <div class="col-xl-12">
                <label>
                    @lang('Customised Short Text (40)')
                </label>
            </div>
            <div class="col-xl-12">
                <x-toggle-switch name="customised_short_test" value="1" :checked="@$product->customised_short_test" />
            </div>
        </div>
    </div>
</div>
