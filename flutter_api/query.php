<?php
header('Content-Type: application/json');
include "./db_cerba.php";

$sqlQuery = $_POST['query'];

$stmt = $db -> prepare($sqlQuery);

$validQuery = $stmt -> execute();

if (stripos($sqlQuery, 'update') !== false) {
    $result = array(['REQUÊTE' => 'La mise à jour a été effectuée']);
}
else {
    $result = $stmt -> fetchAll(PDO::FETCH_ASSOC);
}

echo json_encode($result);