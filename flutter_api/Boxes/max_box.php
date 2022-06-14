<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$acronyme = $_POST['acronyme'];
$sqlQuery = 'SELECT MAX(`CODE BOITE`) FROM boite WHERE `TYPE BOITE` LIKE "'.$acronyme.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);