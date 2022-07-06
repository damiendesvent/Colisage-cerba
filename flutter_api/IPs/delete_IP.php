<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$code = $_POST['code'];

$sqlQuery = 'DELETE FROM `CORRESPONDANCE IP` WHERE `CODE` = '.$code;

$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();