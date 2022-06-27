<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$box = $_POST['box'];
$site = $_POST['site'];

$sqlQuery = 'UPDATE `tube` SET `CODE SITE` = (SELECT `CODE SITE` FROM `sites` WHERE `LIBELLE SITE` = "'.$site.'") WHERE `CODE BOITE` = "'.$box.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
