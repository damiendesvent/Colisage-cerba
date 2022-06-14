<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$libelle = $_POST['libelle'];
$correspondant = $_POST['correspondant'];
$adress = $_POST['adress'];
$cplt = $_POST['cplt'];
$cp = $_POST['cp'];
$city = $_POST['city'];
$collectionSite = $_POST['collectionSite'];
$depositSite = $_POST['depositSite'];
$comment = $_POST['comment'];

$sqlQuery = 'INSERT INTO `sites` (`CODE SITE`, `CORRESPONDANT`, `LIBELLE SITE`, `ADRESSE`, `COMPLEMENT ADRESSE`, `CP`, `VILLE`, `SITE PRELEVEMENT`, `SITE DEPOT`, `COMMENTAIRES CORRESPONDANT`) VALUES 
            ("'.$code.'", "'.$correspondant.'", "'.$libelle.'", "'.$adress.'", "'.$cplt.'", "'.$cp.'", "'.$city.'", "'.$collectionSite.'", "'.$depositSite.'", "'.$comment.'")';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);