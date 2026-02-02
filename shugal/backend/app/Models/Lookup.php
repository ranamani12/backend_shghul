<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Lookup extends Model
{
    public const TYPE_MAJOR = 'major';
    public const TYPE_EXPERIENCE_YEAR = 'experience_year';
    public const TYPE_EDUCATION_LEVEL = 'education_level';

    protected $fillable = [
        'type',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function translations(): HasMany
    {
        return $this->hasMany(LookupTranslation::class);
    }
}
