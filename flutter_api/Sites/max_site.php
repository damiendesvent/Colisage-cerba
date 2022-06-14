<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$sqlQuery = 'SELECT MAX(`CODE SITE`) FROM `sites`';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);