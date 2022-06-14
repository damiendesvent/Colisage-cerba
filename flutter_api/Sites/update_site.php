<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['searchCode'];
$correspondant = $_POST['correspondant'];
$libelle = $_POST['libelle'];
$adress = $_POST['adress'];
$cpltAdress = $_POST['cpltAdress'];
$cp = $_POST['cp'];
$city = $_POST['city'];
$collectionSite = $_POST['collectionSite'] == 'Oui' ? '1' : '0';
$depositSite = $_POST['depositSite'] == 'Oui' ? '1' : '0';
$comment = $_POST['comment'];

$sqlQuery = 'UPDATE sites SET CORRESPONDANT = "'.$correspondant.
            '", `LIBELLE SITE` = "'.$libelle.
            '", ADRESSE = "'.$adress.
            '", `COMPLEMENT ADRESSE` = "'.$cpltAdress.
            '", CP = '.$cp.
            ', VILLE = "'.$city.
            '", `SITE PRELEVEMENT` = '.$collectionSite.
            ', `SITE DEPOT` = '.$depositSite.
            ', `COMMENTAIRES CORRESPONDANT` = "'.$comment.
            '" WHERE `CODE SITE` LIKE "'.$searchCode.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);