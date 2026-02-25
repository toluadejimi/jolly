<?php

use App\Constants\FileInfo;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

Artisan::command('upload-dirs:create', function () {
    $fileInfo = new FileInfo();
    $data = $fileInfo->fileInfo();
    $dirs = [];
    foreach ($data as $key => $item) {
        if (empty($item['path'])) {
            continue;
        }
        $path = $item['path'];
        $dir = pathinfo($path, PATHINFO_EXTENSION) ? dirname($path) : $path;
        $dirs[$dir] = true;
    }

    $storageBase = storage_path('app/public');
    $created = 0;
    $failed = [];
    foreach (array_keys($dirs) as $dir) {
        $full = $storageBase . '/' . $dir;
        if (is_dir($full)) {
            $this->line('<comment>Exists:</comment> storage/app/public/' . $dir);
            continue;
        }
        if (@mkdir($full, 0775, true)) {
            $this->line('<info>Created:</info> storage/app/public/' . $dir);
            $created++;
        } else {
            $failed[] = $full;
            $this->line('<error>Failed:</error> ' . $full);
        }
    }

    if (!file_exists(public_path('storage')) || !is_link(public_path('storage'))) {
        $this->line('Creating storage link (public/storage -> storage/app/public)...');
        Artisan::call('storage:link');
        $this->line('<info>Storage link created.</info>');
    }

    $this->newLine();
    if ($created > 0) {
        $this->info("Created {$created} directory(ies).");
    }
    if (!empty($failed)) {
        $this->error('Could not create: ' . implode(', ', $failed));
        $this->line('Fix: chmod -R 775 storage/app/public');
    }
})->purpose('Create upload dirs in storage/app/public and ensure storage link exists (run after deploy)');
