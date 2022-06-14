<?php
header('Content-Type: application/json; charset=utf-8');

include "../db_cerba.php";

$sqlQuery = 'SELECT * FROM utilisateurs WHERE SUPPRIMEE = 0';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

for($i=0; $i<count($result); $i++){
    $result[$i]['MOT DE PASSE'] = '';
}

echo json_encode($result);