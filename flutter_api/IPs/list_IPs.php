<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$sqlQuery = 'SELECT `CODE`,`PREFIXE IP`,`LIBELLE SITE` FROM `CORRESPONDANCE IP` JOIN `sites` ON `CORRESPONDANCE IP`.`site` = `sites`.`code site`';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);