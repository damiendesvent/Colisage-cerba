<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$tube = $_POST['tube'];

$sqlQuery = 'SELECT * FROM tracabilite WHERE `TUBE` LIKE "'.$tube.'" AND `ACTION` = "VIT" ORDER BY `DATE HEURE ENREGISTREMENT` DESC';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetch(PDO::FETCH_ASSOC);

echo json_encode($result);