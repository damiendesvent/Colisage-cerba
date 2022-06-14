<?php
header('Content-Type: application/json');
include "./db_cerba.php";

$sqlQuery = $_POST['query'];

$stmt = $db -> prepare($sqlQuery);

$validQuery = $stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);