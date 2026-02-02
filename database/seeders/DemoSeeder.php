<?php

namespace Database\Seeders;

use App\Models\Application;
use App\Models\CandidateProfile;
use App\Models\CandidateUnlock;
use App\Models\CompanyProfile;
use App\Models\Country;
use App\Models\CountryTranslation;
use App\Models\Job;
use App\Models\Lookup;
use App\Models\LookupTranslation;
use App\Models\ResumeQuestion;
use App\Models\Setting;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $faker = \Faker\Factory::create();

        $this->seedSettings();
        $this->seedResumeQuestions();
        $this->seedLookups();
        $this->seedCountries();

        $companyUsers = $this->seedCompanies($faker);
        $jobs = $this->seedJobs($faker, $companyUsers);
        $candidateUsers = $this->seedCandidates($faker);

        $this->seedApplications($faker, $jobs, $candidateUsers);
        $this->seedUnlocks($faker, $companyUsers, $candidateUsers);
    }

    private function seedSettings(): void
    {
        Setting::updateOrCreate(
            ['key' => 'candidate_activation_fee'],
            [
                'group' => 'pricing',
                'value' => 1.00,
                'description' => 'Activation fee for candidate profiles',
            ]
        );

        Setting::updateOrCreate(
            ['key' => 'candidate_unlock_fee'],
            [
                'group' => 'pricing',
                'value' => 1.00,
                'description' => 'Fee to unlock a candidate profile',
            ]
        );
    }

    private function seedResumeQuestions(): void
    {
        $questions = [
            ['question' => 'What is your primary field?', 'type' => 'text', 'sort_order' => 1],
            ['question' => 'Years of experience', 'type' => 'text', 'sort_order' => 2],
            ['question' => 'Preferred location', 'type' => 'text', 'sort_order' => 3],
            [
                'question' => 'Availability',
                'type' => 'select',
                'options' => ['Immediate', '1 Month', '3 Months'],
                'sort_order' => 4,
            ],
        ];

        foreach ($questions as $question) {
            ResumeQuestion::updateOrCreate(
                ['question' => $question['question']],
                [
                    'type' => $question['type'],
                    'options' => $question['options'] ?? null,
                    'sort_order' => $question['sort_order'],
                    'is_active' => true,
                ]
            );
        }
    }

    private function seedLookups(): void
    {
        $majors = [
            ['en' => 'Computer Science', 'ar' => 'علوم الحاسب'],
            ['en' => 'Business Administration', 'ar' => 'إدارة الأعمال'],
            ['en' => 'Graphic Design', 'ar' => 'التصميم الجرافيكي'],
            ['en' => 'Civil Engineering', 'ar' => 'الهندسة المدنية'],
        ];

        $experienceYears = [
            ['en' => '0 - 1 Years', 'ar' => '0 - 1 سنة'],
            ['en' => '2 - 3 Years', 'ar' => '2 - 3 سنوات'],
            ['en' => '4 - 6 Years', 'ar' => '4 - 6 سنوات'],
            ['en' => '7+ Years', 'ar' => '7+ سنوات'],
        ];

        $educationLevels = [
            ['en' => 'Diploma', 'ar' => 'دبلوم'],
            ['en' => 'Bachelor', 'ar' => 'بكالوريوس'],
            ['en' => 'Master', 'ar' => 'ماجستير'],
            ['en' => 'PhD', 'ar' => 'دكتوراه'],
        ];

        $this->seedLookupItems(Lookup::TYPE_MAJOR, $majors);
        $this->seedLookupItems(Lookup::TYPE_EXPERIENCE_YEAR, $experienceYears);
        $this->seedLookupItems(Lookup::TYPE_EDUCATION_LEVEL, $educationLevels);
    }

    private function seedLookupItems(string $type, array $items): void
    {
        foreach ($items as $index => $item) {
            $lookup = Lookup::firstOrCreate(
                [
                    'type' => $type,
                    'sort_order' => $index + 1,
                ],
                [
                    'is_active' => true,
                ]
            );

            foreach (['en', 'ar'] as $locale) {
                LookupTranslation::updateOrCreate(
                    [
                        'lookup_id' => $lookup->id,
                        'locale' => $locale,
                    ],
                    [
                        'name' => $item[$locale],
                    ]
                );
            }
        }
    }

    private function seedCountries(): void
    {
        $countries = [
            ['code' => 'US', 'en' => 'United States', 'ar' => 'الولايات المتحدة'],
            ['code' => 'GB', 'en' => 'United Kingdom', 'ar' => 'المملكة المتحدة'],
            ['code' => 'CA', 'en' => 'Canada', 'ar' => 'كندا'],
            ['code' => 'AU', 'en' => 'Australia', 'ar' => 'أستراليا'],
            ['code' => 'NZ', 'en' => 'New Zealand', 'ar' => 'نيوزيلندا'],
            ['code' => 'FR', 'en' => 'France', 'ar' => 'فرنسا'],
            ['code' => 'DE', 'en' => 'Germany', 'ar' => 'ألمانيا'],
            ['code' => 'IT', 'en' => 'Italy', 'ar' => 'إيطاليا'],
            ['code' => 'ES', 'en' => 'Spain', 'ar' => 'إسبانيا'],
            ['code' => 'NL', 'en' => 'Netherlands', 'ar' => 'هولندا'],
            ['code' => 'BE', 'en' => 'Belgium', 'ar' => 'بلجيكا'],
            ['code' => 'CH', 'en' => 'Switzerland', 'ar' => 'سويسرا'],
            ['code' => 'SE', 'en' => 'Sweden', 'ar' => 'السويد'],
            ['code' => 'NO', 'en' => 'Norway', 'ar' => 'النرويج'],
            ['code' => 'DK', 'en' => 'Denmark', 'ar' => 'الدنمارك'],
            ['code' => 'FI', 'en' => 'Finland', 'ar' => 'فنلندا'],
            ['code' => 'AT', 'en' => 'Austria', 'ar' => 'النمسا'],
            ['code' => 'IE', 'en' => 'Ireland', 'ar' => 'أيرلندا'],
            ['code' => 'PT', 'en' => 'Portugal', 'ar' => 'البرتغال'],
            ['code' => 'GR', 'en' => 'Greece', 'ar' => 'اليونان'],
            ['code' => 'PL', 'en' => 'Poland', 'ar' => 'بولندا'],
            ['code' => 'CZ', 'en' => 'Czechia', 'ar' => 'التشيك'],
            ['code' => 'HU', 'en' => 'Hungary', 'ar' => 'المجر'],
            ['code' => 'RO', 'en' => 'Romania', 'ar' => 'رومانيا'],
            ['code' => 'BG', 'en' => 'Bulgaria', 'ar' => 'بلغاريا'],
            ['code' => 'RU', 'en' => 'Russia', 'ar' => 'روسيا'],
            ['code' => 'TR', 'en' => 'Turkey', 'ar' => 'تركيا'],
            ['code' => 'UA', 'en' => 'Ukraine', 'ar' => 'أوكرانيا'],
            ['code' => 'CN', 'en' => 'China', 'ar' => 'الصين'],
            ['code' => 'JP', 'en' => 'Japan', 'ar' => 'اليابان'],
            ['code' => 'KR', 'en' => 'South Korea', 'ar' => 'كوريا الجنوبية'],
            ['code' => 'IN', 'en' => 'India', 'ar' => 'الهند'],
            ['code' => 'PK', 'en' => 'Pakistan', 'ar' => 'باكستان'],
            ['code' => 'BD', 'en' => 'Bangladesh', 'ar' => 'بنغلاديش'],
            ['code' => 'ID', 'en' => 'Indonesia', 'ar' => 'إندونيسيا'],
            ['code' => 'MY', 'en' => 'Malaysia', 'ar' => 'ماليزيا'],
            ['code' => 'SG', 'en' => 'Singapore', 'ar' => 'سنغافورة'],
            ['code' => 'TH', 'en' => 'Thailand', 'ar' => 'تايلاند'],
            ['code' => 'VN', 'en' => 'Vietnam', 'ar' => 'فيتنام'],
            ['code' => 'PH', 'en' => 'Philippines', 'ar' => 'الفلبين'],
            ['code' => 'SA', 'en' => 'Saudi Arabia', 'ar' => 'المملكة العربية السعودية'],
            ['code' => 'AE', 'en' => 'United Arab Emirates', 'ar' => 'الإمارات العربية المتحدة'],
            ['code' => 'KW', 'en' => 'Kuwait', 'ar' => 'الكويت'],
            ['code' => 'QA', 'en' => 'Qatar', 'ar' => 'قطر'],
            ['code' => 'BH', 'en' => 'Bahrain', 'ar' => 'البحرين'],
            ['code' => 'OM', 'en' => 'Oman', 'ar' => 'عُمان'],
            ['code' => 'JO', 'en' => 'Jordan', 'ar' => 'الأردن'],
            ['code' => 'LB', 'en' => 'Lebanon', 'ar' => 'لبنان'],
            ['code' => 'EG', 'en' => 'Egypt', 'ar' => 'مصر'],
            ['code' => 'MA', 'en' => 'Morocco', 'ar' => 'المغرب'],
        ];

        foreach ($countries as $index => $item) {
            $country = Country::firstOrCreate(
                ['code' => $item['code']],
                [
                    'sort_order' => $index + 1,
                    'is_active' => true,
                    'flag_path' => 'https://flagcdn.com/w40/'.strtolower($item['code']).'.png',
                ]
            );

            $country->update([
                'flag_path' => 'https://flagcdn.com/w40/'.strtolower($item['code']).'.png',
            ]);

            foreach (['en', 'ar'] as $locale) {
                CountryTranslation::updateOrCreate(
                    [
                        'country_id' => $country->id,
                        'locale' => $locale,
                    ],
                    [
                        'name' => $item[$locale],
                    ]
                );
            }
        }
    }

    private function seedCompanies($faker)
    {
        $password = Hash::make('Company123');
        $companies = collect([
            ['name' => 'Acme HR', 'email' => 'company1@shugul.test', 'company' => 'Acme Holdings'],
            ['name' => 'Orbit Talent', 'email' => 'company2@shugul.test', 'company' => 'Orbit Talent LLC'],
            ['name' => 'Northwind HR', 'email' => 'company3@shugul.test', 'company' => 'Northwind Group'],
        ])->map(function (array $data) use ($faker, $password) {
            $user = User::firstOrCreate(
                ['email' => $data['email']],
                [
                    'name' => $data['name'],
                    'role' => User::ROLE_COMPANY,
                    'status' => User::STATUS_ACTIVE,
                    'unique_code' => 'COMP-'.Str::upper(Str::random(8)),
                    'password' => $password,
                ]
            );

            CompanyProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'company_name' => $data['company'],
                    'industry' => $faker->randomElement(['Technology', 'Retail', 'Healthcare']),
                    'contact_email' => $user->email,
                    'contact_phone' => $faker->phoneNumber(),
                    'location' => $faker->city(),
                    'website' => $faker->url(),
                    'description' => $faker->sentence(12),
                ]
            );

            return $user;
        });

        return $companies;
    }

    private function seedJobs($faker, $companyUsers)
    {
        $jobs = collect();

        foreach ($companyUsers as $company) {
            for ($i = 0; $i < 3; $i++) {
                $jobs->push(Job::create([
                    'company_id' => $company->id,
                    'title' => $faker->jobTitle(),
                    'description' => $faker->paragraph(4),
                    'requirements' => $faker->paragraph(3),
                    'experience_level' => $faker->randomElement(['Junior', 'Mid', 'Senior']),
                    'location' => $faker->city(),
                    'status' => 'open',
                    'is_active' => true,
                    'published_at' => now()->subDays($faker->numberBetween(1, 20)),
                ]));
            }
        }

        return $jobs;
    }

    private function seedCandidates($faker)
    {
        $password = Hash::make('Candidate123');
        $candidates = collect();

        for ($i = 1; $i <= 6; $i++) {
            $email = "candidate{$i}@shugul.test";
            $user = User::firstOrCreate(
                ['email' => $email],
                [
                    'name' => $faker->name(),
                    'role' => User::ROLE_CANDIDATE,
                    'status' => User::STATUS_ACTIVE,
                    'unique_code' => 'CAND-'.Str::upper(Str::random(8)),
                    'password' => $password,
                ]
            );

            $activated = $i <= 4;
            
            // Get lookup IDs
            $majorIds = Lookup::where('type', Lookup::TYPE_MAJOR)->pluck('id')->toArray();
            $experienceIds = Lookup::where('type', Lookup::TYPE_EXPERIENCE_YEAR)->pluck('id')->toArray();
            $educationIds = Lookup::where('type', Lookup::TYPE_EDUCATION_LEVEL)->pluck('id')->toArray();
            
            $profile = CandidateProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'major_ids' => $majorIds ? [$faker->randomElement($majorIds)] : null,
                    'years_of_experience_id' => $experienceIds ? $faker->randomElement($experienceIds) : null,
                    'skills' => $faker->randomElements(['React', 'Laravel', 'Figma', 'SQL'], 3),
                    'education_id' => $educationIds ? $faker->randomElement($educationIds) : null,
                    'mobile_number' => '+9655'.$faker->numberBetween(1000000, 9999999),
                    'availability' => $faker->randomElement(['Immediate', '1 Month', '3 Months']),
                    'summary' => $faker->sentence(16),
                    'public_slug' => Str::slug($user->name).'-'.Str::lower(Str::random(6)),
                    'is_activated' => $activated,
                    'activated_at' => $activated ? now()->subDays($faker->numberBetween(1, 30)) : null,
                ]
            );

            if ($activated) {
                Transaction::firstOrCreate(
                    [
                        'user_id' => $user->id,
                        'type' => 'candidate_activation',
                    ],
                    [
                        'amount' => 1.00,
                        'currency' => 'KWD',
                        'method' => 'manual',
                        'status' => 'completed',
                        'reference' => (string) Str::uuid(),
                        'meta' => ['candidate_profile_id' => $profile->id],
                    ]
                );
            }

            $candidates->push($user);
        }

        return $candidates;
    }

    private function seedApplications($faker, $jobs, $candidateUsers): void
    {
        $activeCandidates = $candidateUsers->take(4);
        foreach ($activeCandidates as $candidate) {
            $job = $jobs->random();
            Application::firstOrCreate(
                [
                    'job_id' => $job->id,
                    'candidate_id' => $candidate->id,
                ],
                [
                    'status' => 'submitted',
                    'cover_letter' => $faker->paragraph(),
                    'is_paid' => true,
                    'applied_at' => now()->subDays($faker->numberBetween(0, 10)),
                ]
            );
        }
    }

    private function seedUnlocks($faker, $companyUsers, $candidateUsers): void
    {
        $companies = $companyUsers->take(2);
        $candidates = $candidateUsers->take(3);

        foreach ($companies as $company) {
            foreach ($candidates as $candidate) {
                $transaction = Transaction::firstOrCreate(
                    [
                        'user_id' => $company->id,
                        'type' => 'candidate_unlock',
                        'reference' => "unlock-{$company->id}-{$candidate->id}",
                    ],
                    [
                        'amount' => 1.00,
                        'currency' => 'KWD',
                        'method' => 'manual',
                        'status' => 'completed',
                        'meta' => ['candidate_id' => $candidate->id],
                    ]
                );

                CandidateUnlock::firstOrCreate(
                    [
                        'candidate_id' => $candidate->id,
                        'company_id' => $company->id,
                    ],
                    [
                        'transaction_id' => $transaction->id,
                        'unlocked_at' => now()->subDays($faker->numberBetween(0, 5)),
                    ]
                );
            }
        }
    }
}
