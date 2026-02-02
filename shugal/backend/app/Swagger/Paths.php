<?php

use OpenApi\Annotations as OA;

/**
 * @OA\PathItem(
 *     path="/ping",
 *     @OA\Get(
 *         tags={"Admin"},
 *         summary="Ping",
 *         @OA\Response(response=200, description="OK")
 *     )
 * )
 */
