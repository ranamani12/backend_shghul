<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LookupTranslation extends Model
{
    protected $fillable = [
        'lookup_id',
        'locale',
        'name',
    ];

    public function lookup(): BelongsTo
    {
        return $this->belongsTo(Lookup::class);
    }
}
