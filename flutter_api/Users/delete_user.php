<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$cancel = $_POST['cancel'] == 'true' ? '0' : '1';

$sqlQuery = 'UPDATE utilisateurs SET `SUPPRIMEE` = '.$cancel.' where code utilisateur LIKE "'.$code.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

echo json_encode([
    'success' => $result
]);