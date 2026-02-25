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
    $base = public_path();
    $dirs = [];
    foreach ($data as $key => $item) {
        if (empty($item['path'])) {
            continue;
        }
        $path = $item['path'];
        $dir = pathinfo($path, PATHINFO_EXTENSION) ? dirname($path) : $path;
        $full = $base . '/' . $dir;
        $dirs[$full] = true;
    }
    $created = 0;
    $failed = [];
    foreach (array_keys($dirs) as $full) {
        if (is_dir($full)) {
            $this->line('<comment>Exists:</comment> ' . $full);
            continue;
        }
        if (@mkdir($full, 0775, true)) {
            $this->line('<info>Created:</info> ' . $full);
            $created++;
        } else {
            $failed[] = $full;
            $this->line('<error>Failed:</error> ' . $full);
        }
    }
    $this->newLine();
    if ($created > 0) {
        $this->info("Created {$created} directory(ies).");
    }
    if (!empty($failed)) {
        $this->error('Could not create: ' . implode(', ', $failed));
        $this->line('Fix: create them manually and run: chmod -R 775 ' . public_path('assets'));
    }
})->purpose('Create all upload directories under public/assets (run once on server, e.g. after deploy)');
