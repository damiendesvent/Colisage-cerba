<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$box = $_POST['box'];
$type = $_POST['type'];


$sqlQuery = 'INSERT IGNORE INTO `boite` (`code boite`, `type boite`) VALUES ("'.$box.'", "'.$type.'")';
$stmt = $db -> prepare($sqlQuery);
$result = $stmt -> execute();

echo json_encode($result);
