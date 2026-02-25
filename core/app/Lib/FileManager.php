<?php

namespace App\Lib;

use App\Constants\FileInfo;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;

class FileManager {
    /*
    |--------------------------------------------------------------------------
    | File Manager
    |--------------------------------------------------------------------------
    |
    | FileManager class is using to manage edit, update, remove files. Developer
    | can manage any kind of files from here. But some limitations is here for image.
    | This class using a trait to manage the file paths and sizes. Developer can also
    | use this class as a helper function.
    |
    */

    /**
     * The file which will be uploaded
     *
     *
     * @var object
     */
    protected $file;

    /**
     * The path where will be uploaded
     *
     * @var string
     */
    public $path;

    /**
     * The size, if the file is image
     *
     * @var string
     */
    public $size;

    /**
     * Check the file is image or not
     *
     * @var boolean
     */
    protected $isImage;

    /**
     * Thumbnail version size, if required
     * and if the file is image
     *
     * @var string
     */
    public $thumb;

    /**
     * Old filename, which will be removed
     *
     * @var string
     */
    public $old;

    /**
     * Current filename, which is uploading
     *
     * @var string
     */
    public $filename;


    /**
     * Set the file and file type to properties if exist
     *
     * @param $file
     * @return void
     */
    public function __construct($file = null) {
        $this->file = $file;
        if ($file) {
            $imageExtensions = ['jpg', 'jpeg', 'png', 'JPG', 'JPEG', 'PNG'];
            if (in_array($file->getClientOriginalExtension(), $imageExtensions)) {
                $this->isImage = true;
            } else {
                $this->isImage = false;
            }
        }
    }

    /**
     * Get the full filesystem path for uploads (resolves relative paths under public directory).
     *
     * @return string
     */
    protected function getUploadFullPath() {
        $path = $this->path;
        if ($path === '' || $path === null) {
            return $path;
        }
        // Already absolute (Unix or Windows)
        if (str_starts_with($path, '/') || (strlen($path) >= 2 && preg_match('#^[A-Za-z]:[/\\\\]#', $path))) {
            return $path;
        }
        return public_path($path);
    }

    /**
     * File upload process
     *
     * @return void
     */
    public function upload() {
        $uploadPath = $this->getUploadFullPath();

        //create the directory if doesn't exists
        if (!$this->makeDirectory($uploadPath)) {
            throw new \Exception('File could not been created. Path: ' . $uploadPath . ' (create the directory and set permissions: chmod -R 775 assets, or run on server: php artisan upload-dirs:create).');
        }

        //remove the old file if exist
        if ($this->old) {
            $this->removeFile();
        }

        //get the filename
        if (!$this->filename) {
            $this->filename = $this->getFileName();
        }

        //upload file or image
        if ($this->isImage == true) {
            $this->uploadImage();
        } else {
            $this->uploadFile();
        }
    }

    /**
     * Upload the file if this is image
     *
     * @return void
     */
    protected function uploadImage() {
        $uploadPath = $this->getUploadFullPath();
        $manager = new ImageManager(new Driver());
        $image = $manager->read($this->file);

        //resize the
        if ($this->size) {
            $size = explode('x', strtolower($this->size));
            $image->resize($size[0], $size[1]);
        }
        //save the image
        $image->save($uploadPath . '/' . $this->filename);

        //save the image as thumbnail version
        if ($this->thumb) {
            if ($this->old) {
                $this->removeFile($uploadPath . '/thumb_' . $this->old);
            }
            $thumb = explode('x', $this->thumb);
            $manager->read($this->file)->resize($thumb[0], $thumb[1])->save($uploadPath . '/thumb_' . $this->filename);
        }
    }


    /**
     * Upload the file if this is not a image
     *
     * @return void
     */
    protected function uploadFile() {
        $uploadPath = $this->getUploadFullPath();
        $this->file->move($uploadPath, $this->filename);
    }

    /**
     * Make directory if it doesn't exist. Uses 0775 for shared hosting.
     *
     * @param string|null $location Full path to directory
     * @return bool
     */
    public function makeDirectory($location = null) {
        if (!$location) $location = $this->getUploadFullPath();
        if (empty($location)) return false;
        if (is_dir($location)) return true;
        // Create parent directories first with 0775 (helps on shared hosting)
        $parent = dirname($location);
        if (!is_dir($parent) && $parent !== $location) {
            $this->makeDirectory($parent);
        }
        return @mkdir($location, 0775, true) ? true : false;
    }

    /**
     * Remove all directory inside the location
     * Developer can also call this method statically
     *
     * @param $location
     * @return void
     */
    public function removeDirectory($location = null) {
        if (!$location) $location = $this->path;
        if (! is_dir($location)) {
            throw new \InvalidArgumentException("$location must be a directory");
        }
        if (substr($location, strlen($location) - 1, 1) != '/') {
            $location .= '/';
        }
        $files = glob($location . '*', GLOB_MARK);
        foreach ($files as $file) {
            if (is_dir($file)) {
                static::removeDirectory($file);
            } else {
                unlink($file);
            }
        }
        rmdir($location);
    }

    /**
     * Remove the file if exists
     * Developer can also call this method statically
     *
     * @param $path
     * @return void
     */
    public function removeFile($path = null) {
        $basePath = $this->getUploadFullPath();
        if (!$path) $path = $basePath . '/' . $this->old;

        file_exists($path) && is_file($path) ? @unlink($path) : false;

        if ($this->thumb) {
            $path = $basePath . '/thumb_' . $this->old;
            file_exists($path) && is_file($path) ? @unlink($path) : false;
        }
    }

    /**
     * Generating the filename which is uploading
     *
     * @return string
     */
    protected function getFileName() {
        return uniqid() . time() . '.' . $this->file->getClientOriginalExtension();
    }

    /**
     * Get access of array from fileInfo method as non-static method.
     * Also get some others method
     *
     * @return string|void
     */
    public function __call($method, $args) {
        $fileInfo = new FileInfo;
        $filePaths = $fileInfo->fileInfo();
        if (array_key_exists($method, $filePaths)) {
            $path = json_decode(json_encode($filePaths[$method]));
            return $path;
        } else {
            if (method_exists($this, $method)) {
                $this->$method(...$args);
            } else {
                throw new \Exception('File key or method doesn\'t exists.');
            }
        }
    }

    /**
     * Get access some non-static method as static method
     *
     * @return void
     */
    public static function __callStatic($method, $args) {
        $selfClass = new FileManager;
        $selfClass->$method(...$args);
    }
}
