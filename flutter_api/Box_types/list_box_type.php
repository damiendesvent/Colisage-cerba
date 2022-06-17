<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$deleted = $_POST['deleted'] == 'true' ? 1 : 0;

$sqlQuery = 'SELECT * FROM `type boite` WHERE SUPPRIMEE = "'.$deleted.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);