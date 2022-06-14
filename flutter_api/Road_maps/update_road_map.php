<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['searchCode'];
$libelle = $_POST['libelle'];
$tel = $_POST['tel'];
$pda = $_POST['pda'];
$comment = $_POST['comment'];

$sqlQuery = 'UPDATE `entetes feuille de route` SET `LIBELLE TOURNEE` = "'.$libelle.
            '", `TEL CHAUFFEUR` = "'.$tel.
            '", `ORDRE AFFICHAGE PDA` = "'.$pda.
            '", `COMMENTAIRE` = "'.$comment.
            '" WHERE `CODE TOURNEE` LIKE "'.$searchCode.'"';          
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);