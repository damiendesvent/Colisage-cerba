<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$prefix = $_POST['prefix'];
$site = $_POST['site'];

$sqlQuery = 'INSERT INTO `CORRESPONDANCE IP` (`PREFIXE IP`,`SITE`) VALUES ("'.$prefix.'", (SELECT `CODE SITE` from SITES WHERE `LIBELLE SITE` = "'.$site.'"))';

$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();