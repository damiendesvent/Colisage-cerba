<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$libelle = $_POST['libelle'];
$tel = $_POST['tel'];
$pda = $_POST['pda'];
$comment = $_POST['comment'];

$sqlQuery = 'INSERT INTO `entetes feuille de route` (`LIBELLE TOURNEE`, `TEL CHAUFFEUR`, `COMMENTAIRE`, `ORDRE AFFICHAGE PDA`) VALUES 
            ("'.$libelle.'", "'.$tel.'", "'.$comment.'", "'.$pda.'")';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);