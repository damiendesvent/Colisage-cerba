<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['code'];
$sqlQuery = 'SELECT * FROM boite WHERE `CODE BOITE` LIKE "'.$searchCode.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetch(PDO::FETCH_ASSOC);

if (gettype($result) == 'boolean'){
    $result = array('' => '');
}

echo json_encode($result);