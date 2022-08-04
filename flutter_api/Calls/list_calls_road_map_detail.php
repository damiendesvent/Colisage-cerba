<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$site = $_POST['site'];
$order = $_POST['order'];
$isAscending = $_POST['isAscending'] == 'true' ? 'ASC' : 'DESC';

$search = array('À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü', 'Ý');
$replace = array('A', 'A', 'A', 'A', 'A', 'A', 'C', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'O', 'O', 'O', 'O', 'O', 'U', 'U', 'U', 'U', 'Y');

$order = str_replace($search,$replace,$order);

$sqlQuery = 'SELECT `details feuille de route`.`HEURE ARRIVEE`, `sites`.`LIBELLE SITE`, `details feuille de route`.`CODE SITE`, `details feuille de route`.`CODE TOURNEE`, `entetes feuille de route`.`LIBELLE TOURNEE`, COALESCE(`entetes feuille de route`.`TEL CHAUFFEUR`, "NC") AS TELEPHONE, `details feuille de route`.`PASSAGE SUR APPEL` 
            FROM `details feuille de route`
            LEFT JOIN sites ON `details feuille de route`.`CODE SITE` = `sites`.`CODE SITE`
            LEFT JOIN `entetes feuille de route` ON `details feuille de route`.`CODE TOURNEE` = `entetes feuille de route`.`CODE TOURNEE`
            WHERE `sites`.`LIBELLE SITE` = "'.$site.'"  AND `details feuille de route`.`SUPPRIMEE` = 0
            ORDER BY `'.$order.'` '.$isAscending.', `details feuille de route`.`HEURE ARRIVEE` ASC';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);