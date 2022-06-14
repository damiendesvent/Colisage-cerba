<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$field = '`'.$_POST['field'].'`';
$searchText = $_POST['searchText'];
$sqlQuery = 'SELECT * FROM `ENTETES FEUILLE DE ROUTE` WHERE '.$field.' LIKE "%'.$searchText.'%" AND supprimee = 0';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);