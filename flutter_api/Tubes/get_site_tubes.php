<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$box = $_POST['box'];

$sqlQuery = 'SELECT DISTINCT `LIBELLE SITE` FROM `tube` JOIN sites ON tube.`code site` = sites.`code site` WHERE `CODE BOITE` = "'.$box.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

if (gettype($result) == 'boolean'){
    $result = array('LIBELLE SITE' => '');
}

echo json_encode($result);
