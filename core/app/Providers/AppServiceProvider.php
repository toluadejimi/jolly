<?php

namespace App\Providers;

use App\Constants\Status;
use App\Lib\Searchable;
use App\Models\AdminNotification;
use App\Models\Category;
use App\Models\Deposit;
use App\Models\Frontend;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\View;

class AppServiceProvider extends ServiceProvider {
    /**
     * Register any application services.
     */
    public function register(): void {
        Builder::mixin(new Searchable);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void {
        // Custom log viewer view (clear/delete on all channels); fallback to package view
        View::addNamespace('laravel-log-viewer', resource_path('views/vendor/laravel-log-viewer'));
        View::addNamespace('laravel-log-viewer', base_path('vendor/rap2hpoutre/laravel-log-viewer/src/views'));

        if (!cache()->get('SystemInstalled')) {
            $envFilePath = base_path('.env');
            if (!file_exists($envFilePath)) {
                header('Location: install');
                exit;
            }
            $envContents = file_get_contents($envFilePath);
            if (empty($envContents)) {
                header('Location: install');
                exit;
            } else {
                cache()->put('SystemInstalled', true);
            }
        }

        $activeTemplate = 'templates.basic.';
        $activeTemplateAsset = 'assets/templates/basic/';
        try {
            $activeTemplate = activeTemplate();
            $activeTemplateAsset = activeTemplate(true);
        } catch (\Throwable $e) {
            report($e);
        }

        view()->share([
            'activeTemplate' => $activeTemplate,
            'activeTemplateTrue' => $activeTemplateAsset,
            'emptyMessage' => 'Data not found',
            'parentCategories' => collect(),
        ]);

        // Load category nav only when a view needs it (not on every API/logger request)
        view()->composer('*', function ($view) {
            if ($view->offsetExists('parentCategories') && $view['parentCategories']->isNotEmpty()) {
                return;
            }
            static $cached = null;
            if ($cached !== null) {
                $view->with('parentCategories', $cached);
                return;
            }
            try {
                $cached = cache()->remember('parent_categories_nav', 600, function () {
                    return Category::isParent()
                        ->with([
                            'allSubcategories' => function ($q) {
                                $q->orderBy('position');
                            },
                        ])
                        ->orderBy('position')
                        ->get();
                });
            } catch (\Throwable $e) {
                $cached = collect();
                report($e);
            }
            $view->with('parentCategories', $cached);
        });

        view()->composer('admin.partials.sidenav', function ($view) {
            $view->with([
                'bannedUsersCount' => User::banned()->count(),
                'emailUnverifiedUsersCount' => User::emailUnverified()->count(),
                'mobileUnverifiedUsersCount' => User::mobileUnverified()->count(),
                'pendingTicketCount' => SupportTicket::whereIN('status', [Status::TICKET_OPEN, Status::TICKET_REPLY])->count(),
                'pendingDepositsCount' => Deposit::pending()->count(),

                'pendingOrdersCount' => Order::isValidOrder()->pending()->count(),
                'processingOrdersCount' => Order::isValidOrder()->processing()->count(),
                'dispatchedOrdersCount' => Order::isValidOrder()->dispatched()->count(),

                'lowStockProductsCount' => Product::lowStock()->count(),
                'outOfStockProductsCount' => Product::outOfStock()->count(),
                'pendingReviewsCount' => ProductReview::where('status', Status::REVIEW_PENDING)->count(),
                'updateAvailable' => version_compare(gs('available_version'), systemDetails()['version'], '>') ? 'v' . gs('available_version') : false,
            ]);
        });

        view()->composer('admin.partials.topnav', function ($view) {
            $view->with([
                'adminNotifications' => AdminNotification::where('is_read', Status::NO)->with('user')->orderBy('id', 'desc')->take(10)->get(),
                'adminNotificationCount' => AdminNotification::where('is_read', Status::NO)->count(),
            ]);
        });

        view()->composer('partials.seo', function ($view) {
            $seo = Frontend::where('data_keys', 'seo.data')->first();
            $view->with([
                'seo' => $seo ? $seo->data_values : $seo,
            ]);
        });

        // Force SSL disabled on purpose.
        // If you want to re-enable it later, restore the block below.
        // if (gs('force_ssl')) {
        //     \URL::forceScheme('https');
        // }

        Paginator::useBootstrapFive();
    }
}
