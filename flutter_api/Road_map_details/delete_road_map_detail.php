<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['searchCode'];
$delete = $_POST['cancel'] == 'true' ? '0' : '1';

$sqlQuery = 'UPDATE `details feuille de route` SET supprimee = '.$delete.' WHERE `CODE TOURNEE + AVANCEMENT` LIKE "'.$searchCode.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();