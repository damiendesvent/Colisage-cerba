<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$sqlQuery = 'SELECT * FROM `ENTETES FEUILLE DE ROUTE` WHERE supprimee = 0';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);