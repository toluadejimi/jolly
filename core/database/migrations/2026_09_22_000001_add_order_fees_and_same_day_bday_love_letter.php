<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('general_settings', function (Blueprint $table) {
            if (!Schema::hasColumn('general_settings', 'note_fee')) {
                $table->decimal('note_fee', 28, 8)->default(5000)->after('enabled_country_codes');
            }
            if (!Schema::hasColumn('general_settings', 'same_day_bday_love_letter_fee')) {
                $table->decimal('same_day_bday_love_letter_fee', 28, 8)->default(0)->after('note_fee');
            }
        });

        if (Schema::hasColumn('general_settings', 'note_fee')) {
            DB::table('general_settings')->whereNull('note_fee')->update(['note_fee' => 5000]);
        }

        Schema::table('products', function (Blueprint $table) {
            if (!Schema::hasColumn('products', 'same_day_bday_love_letter')) {
                $table->boolean('same_day_bday_love_letter')->default(0)->after('note');
            }
        });
    }

    public function down(): void
    {
        Schema::table('general_settings', function (Blueprint $table) {
            if (Schema::hasColumn('general_settings', 'same_day_bday_love_letter_fee')) {
                $table->dropColumn('same_day_bday_love_letter_fee');
            }
            if (Schema::hasColumn('general_settings', 'note_fee')) {
                $table->dropColumn('note_fee');
            }
        });

        Schema::table('products', function (Blueprint $table) {
            if (Schema::hasColumn('products', 'same_day_bday_love_letter')) {
                $table->dropColumn('same_day_bday_love_letter');
            }
        });
    }
};
