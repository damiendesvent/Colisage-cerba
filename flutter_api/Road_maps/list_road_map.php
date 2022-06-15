<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$numberLimit = $_POST['limit'];
$delete = $_POST['delete'] == 'true' ? '1' : '0';

$sqlQuery = 'SELECT * FROM `ENTETES FEUILLE DE ROUTE` WHERE supprimee = '.$delete.' LIMIT '.$numberLimit;
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);