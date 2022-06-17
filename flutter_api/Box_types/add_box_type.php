<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$code = $_POST['code'];
$libelle = $_POST['libelle'];

$sqlQuery = 'INSERT INTO `type boite` (`acronyme`, `libelle`) VALUES ("'.$code.'", "'.$libelle.'")';
$stmt = $db -> prepare($sqlQuery);
$result = $stmt -> execute();

echo json_encode($result);
