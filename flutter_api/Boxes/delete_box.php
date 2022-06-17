<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$min = $_POST['min'];
$max = $_POST['max'];
$type = $_POST['type'];



$sqlQuery = 'DELETE FROM `boite` WHERE SUBSTR(`CODE BOITE`, 5,8) BETWEEN '.$min.' AND '.$max.' AND `TYPE BOITE` LIKE "'.$type.'"';
$stmt = $db -> prepare($sqlQuery);

$result = $stmt -> execute();


echo json_encode($result);
