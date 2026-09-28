<?php

$config = require base_path('vendor/darkaonline/l5-swagger/config/l5-swagger.php');

return array_replace_recursive($config, [
    'documentations' => [
        'default' => [
            'api' => [
                'title' => 'FlowFi API',
            ],
            'routes' => [
                'api' => 'api/docs',
                'docs' => 'api/docs.json',
            ],
            'paths' => [
                'annotations' => [base_path('app')],
            ],
        ],
    ],
    'enabled' => env('L5_SWAGGER_ENABLED', true),
]);
