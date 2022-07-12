<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$tube = $_POST['tube'];

$sqlQuery = 'DELETE FROM `tracabilite` WHERE `CODE TRACABILITE` = (SELECT `CODE TRACABILITE` WHERE `TUBE` = "'.$tube.'" ORDER BY `CODE TRACABILITE` DESC LIMIT 1)';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();


