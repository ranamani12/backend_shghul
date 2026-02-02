<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ResumeQuestion extends Model
{
    protected $fillable = [
        'question',
        'type',
        'options',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'options' => 'array',
        'is_active' => 'boolean',
    ];
}
