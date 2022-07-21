<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$box = $_POST['box'];

$sqlQuery = 'SELECT * FROM tracabilite WHERE `BOITE` LIKE "'.$box.'" AND `ACTION` = "REC" ORDER BY `DATE HEURE ENREGISTREMENT` DESC LIMIT 1';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetch(PDO::FETCH_ASSOC);

echo json_encode($result);