<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Log;


/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::get('/info', function() {
    phpinfo();
    die();
});


Route::get('/log', function() {
    Log::info("Test log message: " . time());
});

Route::get('/error', function() {
    throw new \Exception("A random error here!");
});
