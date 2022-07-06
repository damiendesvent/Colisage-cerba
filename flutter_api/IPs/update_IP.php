<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$code = $_POST['code'];
$prefix = $_POST['prefix'];
$site = $_POST['site'];

$sqlQuery = 'UPDATE `CORRESPONDANCE IP` SET `PREFIXE IP` = "'.$prefix.'", `SITE` = (SELECT `CODE SITE` from SITES WHERE `LIBELLE SITE` = "'.$site.'") WHERE `CODE` = '.$code;

$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();