<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$box = $_POST['box'];
$sqlQuery = 'SELECT `ACTION`,`LIBELLE SITE` FROM tracabilite JOIN `sites` ON `sites`.`code site` = `tracabilite`.`code site` WHERE `CODE TRACABILITE` = (SELECT MAX(`CODE TRACABILITE`) FROM `tracabilite` WHERE BOITE = "'.$box.'")';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetch(PDO::FETCH_ASSOC);

echo json_encode($result);