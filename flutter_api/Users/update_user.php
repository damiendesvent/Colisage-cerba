<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$searchCode = $_POST['searchCode'];
$firstname = $_POST['firstname'];
$lastname = $_POST['lastname'];
$function = $_POST['function'];
$siteEditing = $_POST['siteEditing'] == 'true' ? 1 : 0;
$roadMapEditing = $_POST['roadMapEditing'] == 'true' ? 1 : 0;
$boxEditing = $_POST['boxEditing'] == 'true' ? 1 : 0;
$userEditing = $_POST['userEditing'] == 'true' ? 1 : 0;
$sqlExecute = $_POST['sqlExecute'] == 'true' ? 1 : 0;
$password = $_POST['password'];

$changePassword = $password == '' ? '' : '", MOT DE PASSE = aes_encrypt("'.$password.'", "%C*F-JaNdRgUkGn2r5u8x/B?D(G+KbPe")';

$sqlQuery = 'UPDATE utilisateurs SET `CODE UTILISATEUR` = "'.$code.
                        '", NOM = "'.$lastname.
                        '", PRENOM = "'.$firstname.
                        '", FONCTION = "'.$function.
                        $changePassword.
                        '", `EDITION SITE` = "'.$siteEditing.
                        '", `EDITION BOITE` = "'.$boxEditing.
                        '", `EDITION UTILISATEUR` = "'.$userEditing.
                        '", `EXECUTION SQL` = "'.$sqlExecute.'" where `CODE UTILISATEUR` LIKE "'.$searchCode.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

echo json_encode([
    'success' => $result
]);