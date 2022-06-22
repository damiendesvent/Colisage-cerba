<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$code = $_POST['code'];

$sqlQuery = 'SELECT * FROM `tube` WHERE `CODE TUBE` = "'.$code.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

if (gettype($result) == 'boolean'){
    $result = array('' => '');
}

echo json_encode($result);