<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['searchCode'];
$delete = $_POST['cancel'] == 'true' ? '0' : '1';

$sqlQuery = 'UPDATE sites SET supprimee = '.$delete.' WHERE `CODE SITE` LIKE "'.$searchCode.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);