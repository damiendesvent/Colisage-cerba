<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

date_default_timezone_set('Europe/Paris');

$user = $_POST['user'];
$tournee = $_POST['tournee'] == null ? 'NULL' : '"'.$_POST['tournee'].'"';
$site = $_POST['site'];
$box = $_POST['box'];
$tube = $_POST['tube'];
$action = $_POST['action'];
$correspondant = $_POST['correspondant'] == null ? 'NULL' : '"'.$_POST['correspondant'].'"';
$registering = $_POST['registering'];
$pgm = $_POST['pgm'];
$lettrage = $_POST['lettrage'] == null ? 'NULL' : '"'.$_POST['lettrage'].'"';
$car = $_POST['car'] == null ? 'NULL' : '"'.$_POST['car'].'"';
$comment = $_POST['comment'] == null ? 'NULL' : '"'.$_POST['comment'].'"';

$synchronizing = date('Y-m-d H:i:s');

if (strlen($tube) > 0) {
    $sqlQuery = 'INSERT INTO `tracabilite` (`UTILISATEUR`, `CODE TOURNEE`, `CODE SITE`, `BOITE`, `TUBE`, `ACTION`, `CORRESPONDANT`, `DATE HEURE ENREGISTREMENT`, `DATE HEURE SYNCHRONISATION`, `CODE ORIGINE`, `NUMERO LETTRAGE`, `CODE VOITURE`, `COMMENTAIRE`) 
                VALUES ("'.$user.'", '.$tournee.', (SELECT `CODE SITE` FROM `sites` WHERE `LIBELLE SITE` = "'.$site.'"), "'.$box.'", "'.$tube.'", "'.$action.'", '.$correspondant.', "'.$registering.'", "'.$synchronizing.'", "'.$pgm.'", '.$lettrage.', '.$car.', '.$comment.')';
    $stmt = $db -> prepare($sqlQuery);
    $result = $stmt -> execute();
    
}

else {
    $sqlQuery = 'INSERT INTO `tracabilite` (`UTILISATEUR`, `CODE TOURNEE`, `CODE SITE`, `BOITE`, `TUBE`, `ACTION`, `CORRESPONDANT`, `DATE HEURE ENREGISTREMENT`, `DATE HEURE SYNCHRONISATION`, `CODE ORIGINE`, `NUMERO LETTRAGE`, `CODE VOITURE`, `COMMENTAIRE`) 
                    VALUES ("'.$user.'", '.$tournee.', (SELECT `CODE SITE` FROM `sites` WHERE `LIBELLE SITE` = "'.$site.'"), "'.$box.'", NULL, "'.$action.'", '.$correspondant.', "'.$registering.'", "'.$synchronizing.'", "'.$pgm.'", '.$lettrage.', '.$car.', '.$comment.')';
        $stmt = $db -> prepare($sqlQuery);
        $result = $stmt -> execute();
}