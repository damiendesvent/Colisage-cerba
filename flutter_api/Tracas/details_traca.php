<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['searchCode'];
$sqlQuery = 'SELECT * FROM tracabilite WHERE `CODE TRACABILITE` LIKE "'.$searchCode.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);