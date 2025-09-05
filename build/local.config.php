<?php
return [
    'logger' => [
        'log' => true,
        'priority' => \Laminas\Log\Logger::NOTICE,
    ],
    'http_client' => [
        'sslcapath' => null,
        'sslcafile' => null,
    ],
    'cli' => [
        'phpcli_path' => null,
    ],
    'thumbnails' => [
        'types' => [
            'large' => ['constraint' => intval(getenv('THUMBNAIL_LARGE_CONSTRAINT') ?: 1000) ],
            'medium' => ['constraint' => intval(getenv('THUMBNAIL_MEDIUM_CONSTRAINT') ?: 600) ],
            'square' => ['constraint' => intval(getenv('THUMBNAIL_SQUARE_CONSTRAINT') ?: 400)],
        ],
        'thumbnailer_options' => [
            'imagemagick_dir' => null,
        ],
    ],
    'translator' => [
        'locale' => 'en_US',
    ],
    'service_manager' => [
        'aliases' => [
            'Omeka\File\Store' => 'Omeka\File\Store\Local',
            'Omeka\File\Thumbnailer' => 'Omeka\File\Thumbnailer\ImageMagick',
        ],
    ],
    'mail' => [
        'transport' => [
            'type' => 'smtp',
            'options' => [
                'name' => 'smtp',
                'host' => getenv('SMTP_HOST'), //'127.0.0.1'
                'port' => getenv('SMTP_PORT'), // 25, 465 for 'ssl', and 587 for 'tls'
                'connection_class' => 'smtp', // 'plain', 'login', or 'crammd5'
                'connection_config' => array_filter([
                    'username' => getenv('SMTP_USER') ?: null,
                    'password' => getenv('SMTP_PASSWORD') ?: null,
                    'ssl' => getenv('SMTP_CONNECTION_TYPE') ?: null, // 'ssl' or 'tls'
                    'use_complete_quit' => true,
                ], fn($v) => $v !== null),
            ],
        ],
    ],
];