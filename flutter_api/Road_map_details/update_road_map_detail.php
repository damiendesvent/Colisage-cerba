<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$searchCode = $_POST['searchCode'];
$libelleSite = $_POST['libelleSite'];
$time = $_POST['time'];
$onCall = $_POST['onCall'] == 'Oui' ? 1 : 0;
$comment = $_POST['comment'];

$sqlQuery = 'UPDATE `details feuille de route` SET 
            `CODE SITE` = (SELECT `CODE SITE` FROM `sites` WHERE `libelle site` LIKE "'.$libelleSite.
            '" LIMIT 1), `HEURE ARRIVEE` = "'.$time.
            '", `COMMENTAIRE` = "'.$comment.
            '", `PASSAGE SUR APPEL` = "'.$onCall.
            '" WHERE `CODE TOURNEE + AVANCEMENT` LIKE "'.$searchCode.'"';          
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();