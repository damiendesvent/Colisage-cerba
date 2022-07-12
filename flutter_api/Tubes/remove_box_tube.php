<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$tube = $_POST['tube'];


$sqlQuery = 'SELECT * FROM `tube` WHERE `CODE TUBE` = "'.$tube.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

if (gettype($result) != 'boolean') {
    $sqlQuery = 'DELETE FROM `tube` WHERE `CODE TUBE` = "'.$tube.'"';
    $stmt = $db -> prepare($sqlQuery);
    $stmt -> execute();
}
