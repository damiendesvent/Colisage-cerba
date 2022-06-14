<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$progressCode = $_POST['progressCode'];
$roadMapCode = $_POST['roadMapCode'];
$siteLibelle = $_POST['siteLibelle'];
$time = $_POST['time'];
$onCall = $_POST['onCall'];
$comment = $_POST['comment'];

$code = $roadMapCode.str_pad($progressCode, 3, '0', STR_PAD_LEFT);

$sqlQuery = 'INSERT INTO `details feuille de route` (`CODE AVANCEMENT`, `CODE TOURNEE`, `CODE TOURNEE + AVANCEMENT`, `CODE SITE`, `HEURE ARRIVEE`, `COMMENTAIRE`, `PASSAGE SUR APPEL`) VALUES 
            ("'.$progressCode.'", "'.$roadMapCode.'", "'.$code.'", (SELECT `CODE SITE` FROM `sites` WHERE `libelle site` LIKE "'.$siteLibelle.
            '"), "'.$time.'", "'.$comment.'", "'.$onCall.'")';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);