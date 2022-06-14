<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$firstname = $_POST['firstname'];
$lastname = $_POST['lastname'];
$function = $_POST['function'];
$siteEditing = $_POST['siteEditing'] == 'true' ? 1 : 0;
$roadMapEditing = $_POST['roadMapEditing'] == 'true' ? 1 : 0;
$boxEditing = $_POST['boxEditing'] == 'true' ? 1 : 0;
$userEditing = $_POST['userEditing'] == 'true' ? 1 : 0;
$sqlExecute = $_POST['sqlExecute'] == 'true' ? 1 : 0;
$password = $_POST['password'];

$search = array('À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü', 'Ý');
$replace = array('A', 'A', 'A', 'A', 'A', 'A', 'C', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'O', 'O', 'O', 'O', 'O', 'U', 'U', 'U', 'U', 'Y');
$code = str_replace($search,$replace,$code);

$sqlQuery = 'INSERT INTO `utilisateurs` (`code utilisateur`, `nom`, `prenom`, `fonction`, `mot de passe`, `EDITION SITE`, `EDITION FEUILLE DE ROUTE`,`EDITION BOITE`,`EDITION UTILISATEUR`,`EXECUTION SQL`) VALUES ("'.$code.
                        '", "'.$lastname.
                        '", "'.$firstname.
                        '", "'.$function.
                        '", aes_encrypt("'.$password.'", "%C*F-JaNdRgUkGn2r5u8x/B?D(G+KbPe")'.
                        ', "'.$siteEditing.
                        '", "'.$roadMapEditing.
                        '", "'.$boxEditing.
                        '", "'.$userEditing.
                        '", "'.$sqlExecute.'")';
$stmt = $db -> prepare($sqlQuery);

$result = $stmt -> execute();

echo json_encode($result);
