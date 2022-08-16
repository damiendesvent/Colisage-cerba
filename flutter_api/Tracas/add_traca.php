<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

date_default_timezone_set('Europe/Paris');

$user = $_POST['user'];
$tournee = $_POST['tournee'] == null || $_POST['tournee'] == '' ? 'NULL' : '(SELECT `CODE TOURNEE` FROM `ENTETES FEUILLE DE ROUTE` WHERE `LIBELLE TOURNEE` = "'.$_POST['tournee'].'" LIMIT 1)';
$site = $_POST['site'];
$box = $_POST['box'];
$tube = $_POST['tube'];
$action = $_POST['action'];
$registering = $_POST['registering'];
$pgm = $_POST['pgm'];
$lettrage = $_POST['lettrage'] == null ? 'NULL' : '"'.$_POST['lettrage'].'"';
$car = $_POST['car'] == null || $_POST['car'] == '' ? 'NULL' : '"'.$_POST['car'].'"';
$prelevement = $_POST['prelevement'] == null ? 'NULL' : '"'.$_POST['prelevement'].'"';
$contact = $_POST['contact'] == null ? 'NULL' : '"'.$_POST['contact'].'"';
$ok = $_POST['ok'] == null ? 'NULL' : ($_POST['ok'] == 'true' ? '1' : '0');
$comment = $_POST['comment'] == null || $_POST['comment'] == '' ? 'NULL' : '"'.$_POST['comment'].'"';

$synchronizing = date('Y-m-d H:i:s');

if (strlen($tube) > 0) {
    $sqlQuery = 'INSERT INTO `tracabilite` (`UTILISATEUR`, `CODE TOURNEE`, `CODE SITE`, `BOITE`, `TUBE`, `ACTION`, `DATE HEURE ENREGISTREMENT`, `DATE HEURE SYNCHRONISATION`, `CODE ORIGINE`, `NUMERO LETTRAGE`, `CODE VOITURE`, `COMMENTAIRE`) 
                VALUES ("'.$user.'", '.$tournee.', (SELECT `CODE SITE` FROM `sites` WHERE `LIBELLE SITE` = "'.$site.'" LIMIT 1), "'.$box.'", "'.$tube.'", "'.$action.'", "'.$registering.'", "'.$synchronizing.'", "'.$pgm.'", '.$lettrage.', '.$car.', '.$comment.')';
    $stmt = $db -> prepare($sqlQuery);
    $result = $stmt -> execute();
    
}

else {
    $sqlQuery = 'INSERT INTO `tracabilite` (`UTILISATEUR`, `CODE TOURNEE`, `CODE SITE`, `BOITE`, `ACTION`, `DATE HEURE ENREGISTREMENT`, `DATE HEURE SYNCHRONISATION`, `CODE ORIGINE`, `NUMERO LETTRAGE`, `CODE VOITURE`, `CONTACT`, `PRELEVEMENT`, `OK`, `COMMENTAIRE`) 
                    VALUES ("'.$user.'", '.$tournee.', (SELECT `CODE SITE` FROM `sites` WHERE `LIBELLE SITE` = "'.$site.'" LIMIT 1), "'.$box.'", "'.$action.'", "'.$registering.'", "'.$synchronizing.'", "'.$pgm.'", '.$lettrage.', '.$car.', '.$contact.', '.$prelevement.', '.$ok.', '.$comment.')';
        $stmt = $db -> prepare($sqlQuery);
        $result = $stmt -> execute();
}