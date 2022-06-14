<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['searchCode'];
$sqlQuery = 'SELECT * FROM sites WHERE `CODE SITE` LIKE "'.$searchCode.'" AND supprimee = 0';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);