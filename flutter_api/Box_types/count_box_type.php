<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$code = $_POST['code'];

$sqlQuery = 'SELECT COUNT(*) FROM `type boite` WHERE ACRONYME = "'.$code.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

echo json_encode($result);