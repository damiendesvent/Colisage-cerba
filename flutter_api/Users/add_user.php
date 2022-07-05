<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$firstname = $_POST['firstname'];
$lastname = $_POST['lastname'];
$function = $_POST['function'];
$siteRights = $_POST['siteRights'];
$roadMapRights = $_POST['roadMapRights'];
$boxRights = $_POST['boxRights'];
$userRights = $_POST['userRights'];
$sqlExecute = $_POST['sqlExecute'] == 'true' ? '1' : '0';
$settingsAccess = $_POST['settingsAccess'] == 'true' ? '1' : '0';
$password = $_POST['password'];

$search = array('À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü', 'Ý');
$replace = array('A', 'A', 'A', 'A', 'A', 'A', 'C', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'O', 'O', 'O', 'O', 'O', 'U', 'U', 'U', 'U', 'Y');
$code = str_replace($search,$replace,$code);

$sqlQuery = 'INSERT INTO `utilisateurs` (`code utilisateur`, `nom`, `prenom`, `fonction`, `mot de passe`, `DROITS SITE`, `DROITS FEUILLE DE ROUTE`,`DROITS BOITE`,`DROITS UTILISATEUR`,`EXECUTION SQL`, `ACCES PARAMETRES`) VALUES ("'.$code.
                        '", "'.$lastname.
                        '", "'.$firstname.
                        '", "'.$function.
                        '", aes_encrypt("'.$password.'", "%C*F-JaNdRgUkGn2r5u8x/B?D(G+KbPe")'.
                        ', '.$siteRights.
                        ', '.$roadMapRights.
                        ', '.$boxRights.
                        ', '.$userRights.
                        ', '.$sqlExecute.
                        ', '.$settingsAccess.
                        ')';
$stmt = $db -> prepare($sqlQuery);

$result = $stmt -> execute();

echo json_encode($result);
