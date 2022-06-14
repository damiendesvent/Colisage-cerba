<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$codeTournee = $_POST['codeTournee'];
$sqlQuery = 'SELECT `CODE AVANCEMENT`,`CODE TOURNEE + AVANCEMENT`,sites.`CODE SITE`,sites.`LIBELLE SITE`,`HEURE ARRIVEE`,`COMMENTAIRE`,`PASSAGE SUR APPEL` FROM `details feuille de route` JOIN `sites` ON `details feuille de route`.`CODE SITE` = sites.`CODE SITE` WHERE `CODE TOURNEE` LIKE '.$codeTournee.' AND `details feuille de route`.`SUPPRIMEE` = 0';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);