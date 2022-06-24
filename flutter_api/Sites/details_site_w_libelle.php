<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['libelle'];
$sqlQuery = 'SELECT * FROM sites WHERE `LIBELLE SITE` LIKE "'.$searchCode.'" AND supprimee = 0';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetch(PDO::FETCH_ASSOC);

echo json_encode($result);