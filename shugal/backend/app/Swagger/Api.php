<?php

namespace App\Swagger;

use OpenApi\Annotations as OA;

/**
 * @OA\OpenApi(
 *     @OA\Info(
 *         title="Shugul API",
 *         version="1.0.0",
 *         description="API documentation for Shugul platform"
 *     ),
 *     @OA\Server(
 *         url="http://127.0.0.1:8000/api",
 *         description="Local API server"
 *     )
 * )
 *
 * @OA\SecurityScheme(
 *     securityScheme="bearerAuth",
 *     type="http",
 *     scheme="bearer",
 *     bearerFormat="JWT"
 * )
 *
 * @OA\Tag(name="Auth", description="Authentication endpoints")
 * @OA\Tag(name="Admin", description="Admin endpoints")
 *
 * @OA\PathItem(
 *     path="/health",
 *     @OA\Get(
 *         tags={"Admin"},
 *         summary="Health check",
 *         @OA\Response(response=200, description="OK")
 *     )
 * )
 */
class Api
{
    /**
     * @OA\Post(
     *     path="/auth/register",
     *     tags={"Auth"},
     *     summary="Register candidate or company",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name","email","password","password_confirmation","role"},
     *             @OA\Property(property="name", type="string"),
     *             @OA\Property(property="email", type="string", format="email"),
     *             @OA\Property(property="password", type="string", format="password"),
     *             @OA\Property(property="password_confirmation", type="string", format="password"),
     *             @OA\Property(property="role", type="string", example="candidate"),
     *             @OA\Property(property="company_name", type="string")
     *         )
     *     ),
     *     @OA\Response(response=201, description="Registered")
     * )
     */
    public function register(): void {}

    /**
     * @OA\Post(
     *     path="/auth/login",
     *     tags={"Auth"},
     *     summary="Login as candidate or company",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"email","password"},
     *             @OA\Property(property="email", type="string", format="email"),
     *             @OA\Property(property="password", type="string", format="password")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Authenticated")
     * )
     */
    public function login(): void {}

    /**
     * @OA\Post(
     *     path="/auth/admin/login",
     *     tags={"Auth"},
     *     summary="Admin login",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"email","password"},
     *             @OA\Property(property="email", type="string", format="email"),
     *             @OA\Property(property="password", type="string", format="password")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Authenticated")
     * )
     */
    public function adminLogin(): void {}

    /**
     * @OA\Get(
     *     path="/auth/me",
     *     tags={"Auth"},
     *     summary="Get current user",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function me(): void {}

    /**
     * @OA\Get(
     *     path="/admin/candidates",
     *     tags={"Admin"},
     *     summary="List candidates",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(name="q", in="query", @OA\Schema(type="string")),
     *     @OA\Parameter(name="status", in="query", @OA\Schema(type="string")),
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function candidates(): void {}

    /**
     * @OA\Get(
     *     path="/admin/candidates/{candidate}",
     *     tags={"Admin"},
     *     summary="Candidate profile",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(name="candidate", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function candidateProfile(): void {}

    /**
     * @OA\Get(
     *     path="/admin/companies",
     *     tags={"Admin"},
     *     summary="List companies",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(name="q", in="query", @OA\Schema(type="string")),
     *     @OA\Parameter(name="status", in="query", @OA\Schema(type="string")),
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function companies(): void {}

    /**
     * @OA\Get(
     *     path="/admin/companies/{company}",
     *     tags={"Admin"},
     *     summary="Company profile",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(name="company", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function companyProfile(): void {}

    /**
     * @OA\Get(
     *     path="/admin/jobs",
     *     tags={"Admin"},
     *     summary="List jobs",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function jobs(): void {}

    /**
     * @OA\Get(
     *     path="/admin/transactions",
     *     tags={"Admin"},
     *     summary="List transactions",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function transactions(): void {}

    /**
     * @OA\Get(
     *     path="/admin/settings",
     *     tags={"Admin"},
     *     summary="List settings",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(name="group", in="query", @OA\Schema(type="string")),
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function settings(): void {}

    /**
     * @OA\Get(
     *     path="/admin/resume-questions",
     *     tags={"Admin"},
     *     summary="List resume questions",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="OK")
     * )
     */
    public function resumeQuestions(): void {}
}
