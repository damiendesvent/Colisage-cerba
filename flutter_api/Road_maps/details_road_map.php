<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$libelle = $_POST['libelle'];
$sqlQuery = 'SELECT COUNT(*) FROM `entetes feuille de route` WHERE `LIBELLE TOURNEE` = "'.$libelle.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result1 = $stmt -> fetchAll(PDO::FETCH_ASSOC);


$order = $_POST['order'];
$sqlQuery = 'SELECT COUNT(*) FROM `entetes feuille de route` WHERE `ORDRE AFFICHAGE PDA` = "'.$order.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result2 = $stmt -> fetchAll(PDO::FETCH_ASSOC);

$result = array('libelleExist' => $result1[0]['COUNT(*)'],
                'orderExist' => $result2[0]['COUNT(*)']);

echo json_encode($result);