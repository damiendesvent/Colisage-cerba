<?php

$db_hostname = '127.0.0.1';
$db_name = 'cerba';
$db_username = 'root';
$db_password = 'root';

try{
    $db = new PDO('mysql:host='.$db_hostname.';dbname='.$db_name.';charset=utf8', $db_username, $db_password, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
}
catch (Exception $e)
{
    die('Erreur : '.$e->getMessage());
}
?>