<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$name = $_POST['name'];
$newValue = $_POST['newValue'];

$sqlQuery = 'UPDATE `constantes` SET `Valeur` = "'.$newValue.'" WHERE `Nom` = "'.$name.'"';

$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();