<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$code = $_POST['code'];

$sqlQuery = 'SELECT * FROM `tube` WHERE `CODE BOITE` = "'.$code.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);