<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$sqlQuery = 'INSERT INTO `box` (`code boite`, `type boite`) VALUES (":code", ":type")';
$stmt = $db -> prepare($sqlQuery);
$result = $stmt -> execute([
    'code' => $_POST['code'],
    'type' => $_POST['type'],
]);

echo json_encode($result);
