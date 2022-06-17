<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$newLibelle = $_POST['newLibelle'];
$acronyme = $_POST['acronyme'];

$sqlQuery = 'UPDATE `type boite` SET `LIBELLE` = "'.$newLibelle.'" WHERE `type boite`.`ACRONYME` = "'.$acronyme.'"';

$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();