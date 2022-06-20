<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];

$sqlQuery = 'SELECT COUNT(*) FROM utilisateurs WHERE `CODE UTILISATEUR` = "'.$code.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

echo json_encode($result);

?>