<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$tube = $_POST['tube'];
$box = $_POST['box'];

$tube = substr($tube, 1, strlen($tube) - 2);
$tube = explode(',',$tube);

for ($i = 0; $i < count($tube); $i ++) {
    $sqlQuery = 'UPDATE `tube` SET `CODE BOITE` = "'.$box.'" WHERE `CODE TUBE` = "'.$tube[i].'"';
    $stmt = $db -> prepare($sqlQuery);
    $stmt -> execute();
}