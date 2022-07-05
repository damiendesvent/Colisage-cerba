<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$searchCode = $_POST['searchCode'];
$firstname = $_POST['firstname'];
$lastname = $_POST['lastname'];
$function = $_POST['function'];
$siteRights = $_POST['siteRights'];
$roadMapRights = $_POST['roadMapRights'];
$boxRights = $_POST['boxRights'];
$userRights = $_POST['userRights'];
$sqlExecute = $_POST['sqlExecute'] == 'true' ? '1' : '0';
$settingsAccess = $_POST['settingsAccess'] == 'true' ? '1' : '0';

$sqlQuery = 'UPDATE utilisateurs SET `CODE UTILISATEUR` = "'.$code.
                        '", NOM = "'.$lastname.
                        '", PRENOM = "'.$firstname.
                        '", FONCTION = "'.$function.
                        '", `DROITS SITE` = '.$siteRights.
                        ', `DROITS FEUILLE DE ROUTE` = '.$roadMapRights.
                        ', `DROITS BOITE` = '.$boxRights.
                        ', `DROITS UTILISATEUR` = '.$userRights.
                        ', `EXECUTION SQL` = '.$sqlExecute.
                        ', `ACCES PARAMETRES` = '.$settingsAccess.' where `CODE UTILISATEUR` LIKE "'.$searchCode.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();