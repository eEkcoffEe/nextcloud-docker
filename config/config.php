<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'apps_paths' => 
  array (
    0 => 
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 => 
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'redis',
    'password' => '',
    'port' => 6379,
  ),
  'overwritehost' => 'nextcloud-element-qwen.duckdns.org',
  'overwriteprotocol' => 'https',
  'overwrite.cli.url' => 'https://nextcloud-element-qwen.duckdns.org',
  'upgrade.disable-web' => true,
  'passwordsalt' => 'iG6dj61eDmDT1dlKHaCUgpYoB+J6JG',
  'secret' => '0SiK2mVjJ4hbh6THHeJhMxhYwRRozBi2024K4ImLau6Huix/',
  'trusted_domains' => 
  array (
    0 => 'localhost',
    1 => 'nextcloud.element-qwen.duckdns.org',
    2 => 'talk.element-qwen.duckdns.org',
    3 => 'nextcloud-element-qwen.duckdns.org',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'pgsql',
  'version' => '32.0.6.1',
  'dbname' => 'nextcloud',
  'dbhost' => 'db',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'oc_admin',
  'dbpassword' => 'wWaDjRMgmlkjuVIIOnTyIaGcK6dYsa',
  'installed' => true,
  'instanceid' => 'oc9h2i0d1b00',
  'forbidden_filename_basenames' => 
  array (
    0 => 'con',
    1 => 'prn',
    2 => 'aux',
    3 => 'nul',
    4 => 'com0',
    5 => 'com1',
    6 => 'com2',
    7 => 'com3',
    8 => 'com4',
    9 => 'com5',
    10 => 'com6',
    11 => 'com7',
    12 => 'com8',
    13 => 'com9',
    14 => 'com¹',
    15 => 'com²',
    16 => 'com³',
    17 => 'lpt0',
    18 => 'lpt1',
    19 => 'lpt2',
    20 => 'lpt3',
    21 => 'lpt4',
    22 => 'lpt5',
    23 => 'lpt6',
    24 => 'lpt7',
    25 => 'lpt8',
    26 => 'lpt9',
    27 => 'lpt¹',
    28 => 'lpt²',
    29 => 'lpt³',
  ),
  'forbidden_filename_characters' => 
  array (
    0 => '<',
    1 => '>',
    2 => ':',
    3 => '"',
    4 => '|',
    5 => '?',
    6 => '*',
    7 => '\\',
    8 => '/',
  ),
  'forbidden_filename_extensions' => 
  array (
    0 => ' ',
    1 => '.',
    2 => '.filepart',
    3 => '.part',
  ),
  'trusted_proxies' => 
  array (
    0 => '127.0.0.1',
    1 => '::1',
    2 => '172.17.0.0/16',
    3 => '172.19.0.0/16',
  ),
  'forwarded_for_headers' => 
  array (
    0 => 'HTTP_X_FORWARDED_FOR',
  ),
  'maintenance_window_start' => 3,
  'spreed' => 
  array (
    'signaling_servers' => 
    array (
      0 => 
      array (
        'url' => 'https://nextcloud-element-qwen.duckdns.org/standalone-signaling/',
        'verify' => true,
      ),
    ),
    'signaling_mode' => 'external',
  ),
  'maintenance' => false,
  'csrf.disabled-domains' => '["localhost"]',
  'httpprotocol' => 'https',
  'loglevel' => '2',
  'mail_smtpmode' => 'smtp',
  'mail_smtpsecure' => 'ssl',
  'mail_sendmailmode' => 'smtp',
);
