<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$tube = $_POST['tube'];
$box = $_POST['box'];

$tube = substr($tube, 1, strlen($tube) - 2);
$tube = explode(',',$tube);

$values = '';

for ($i = 0; $i < count($tube); $i ++) {
    $values .= '("'.$tube[$i].'", "'.$box.'"),';
}

$values = substr($values, 0, strlen($values) - 1);

$sqlQuery = 'INSERT INTO `tube` (`code tube`, `code boite`) VALUES '.$values.';';
$stmt = $db -> prepare($sqlQuery);
$result = $stmt -> execute();

echo json_encode($result);