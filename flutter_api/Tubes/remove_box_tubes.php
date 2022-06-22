<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$tube = $_POST['tube'];

$tube = substr($tube, 1, strlen($tube) - 2);
$tube = explode(',',$tube);
$tube = str_replace(' ','', $tube);

for ($i = 0; $i < count($tube); $i ++) {
    $sqlQuery = 'UPDATE `tube` SET `CODE BOITE` = "NULL" WHERE `CODE TUBE` = "'.$tube[$i].'"';
    $stmt = $db -> prepare($sqlQuery);
    $stmt -> execute();
    echo json_encode($sqlQuery);
}