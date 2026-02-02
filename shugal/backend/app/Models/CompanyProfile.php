<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CompanyProfile extends Model
{
    protected $fillable = [
        'user_id',
        'company_name',
        'country_id',
        'logo_path',
        'contact_email',
        'contact_phone',
        'mobile_number',
        'civil_id',
        'majors',
        'license_path',
        'website',
        'description',
    ];

    protected $casts = [
        'majors' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
