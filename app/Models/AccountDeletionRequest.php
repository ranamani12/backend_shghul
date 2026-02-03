<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AccountDeletionRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'email',
        'phone',
        'account_type',
        'reason',
        'comments',
        'reference',
        'status',
        'processed_at',
        'processed_by',
    ];

    protected $casts = [
        'processed_at' => 'datetime',
    ];

    public function processedBy()
    {
        return $this->belongsTo(User::class, 'processed_by');
    }
}
