<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$libelle = $_POST['libelle'];
$tel = $_POST['tel'];
$pda = $_POST['pda'];
$comment = $_POST['comment'];

$sqlQuery = 'INSERT INTO `entetes feuille de route` (`CODE TOURNEE`, `LIBELLE TOURNEE`, `TEL CHAUFFEUR`, `COMMENTAIRE`, `ORDRE AFFICHAGE PDA`) VALUES 
            ("'.$code.'", "'.$libelle.'", "'.$tel.'", "'.$comment.'", "'.$pda.'")';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);