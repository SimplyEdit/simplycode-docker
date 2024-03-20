<?php

$volume = listVolumeContent();
$templateValues = [
    $_SERVER['SERVER_SIGNATURE'],
    getenv('USER_ID') . ':' . getenv('USER_GID'),
    exec('whoami'),
    implode('</code></li><li><code>', $volume),
];

$responseCode = 403;
$template = <<<'HTML'
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html lang="en">
<head>
  <title>403 Forbidden</title>
</head>
<body>
  <h1>Forbidden</h1>
  <p>You don't have permission to access this resource.</p>
  <hr>
  %s
  <hr>
  <details>
    <summary>Technical details</summary>
    <h2>Technical details</h2>
    <p>uid/gid: <code>%s</code></p>
    <p>user: <code>%s</code></p>
    <p>Volume contents:</p>
    <ul>
      <li><code>%s</code></li>
    </ul>
  </details>
</body>
</html>
HTML;

function listVolumeContent(): array
{
    $files = [];
    $folders = [];

    $iterator = new FilesystemIterator(
        '/var/www/www/api/data/',
        FilesystemIterator::SKIP_DOTS | FilesystemIterator::KEY_AS_FILENAME
    );

    foreach ($iterator as $file) {
        $type = $file->getType();
        switch ($type) {
            case 'dir':
                $filename = $file->getFilename() . '/';
                $folders[] = $filename;
                break;
            case 'link':
                $filename = $file->getFilename() . ' -> ' . readlink($file->getPathname());
                $files[] = $filename;
                break;
            case 'file':
            default:
                $filename = $file->getFilename();
                $files[] = $filename;
                break;
        }
    }

    sort($folders);
    sort($files);

    return array_merge($folders, $files);
}

if (
    $_SERVER['REQUEST_URI'] === '/' && ! file_exists('/var/www/www/api/data/generated.html')
) {
    $responseCode = 200;
    $template = <<<'HTML'
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html lang="en">
<head>
  <title>Welcome to SimplyCode</title>
</head>
<body>
  <h1>Welcome to SimplyCode!</h1>
  <p>
    This looks like your first visit.
    <strong>Go to <a href="%s">%s</a> to start building something awesome.</strong>
    <!-- @TODO: Add a link to a turorial or reference to help the user
        See: https://github.com/SimplyEdit/simplycode-docker/issues/12
      -->
  </p>
  <hr>
  %s
  <hr>
  <details>
    <summary>Technical details</summary>
    <h2>Technical details</h2>
    <p>uid/gid: <code>%s</code></p>
    <p>user: <code>%s</code></p>
    <p>Volume contents:</p>
    <ul>
      <li><code>%s</code></li>
    </ul>
  </details>
</body>
</html>
HTML;
    $templateValues = array_merge([],
        [
        "{$_SERVER['REQUEST_SCHEME']}://{$_SERVER['SERVER_NAME']}:{$_SERVER['SERVER_PORT']}/simplycode",
        '/simplycode',
        ],
        $templateValues
    );
}

http_response_code($responseCode);
header('Content-Type: text/html');
vprintf($template, $templateValues);
