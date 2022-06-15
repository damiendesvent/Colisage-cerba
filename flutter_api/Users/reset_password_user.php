<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$password = $_POST['password'];

$sqlQuery = 'UPDATE utilisateurs SET `MOT DE PASSE` = aes_encrypt("'.$password.'", "%C*F-JaNdRgUkGn2r5u8x/B?D(G+KbPe") WHERE `CODE UTILISATEUR` LIKE "'.$code.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

echo json_encode([
    'success' => $result
]);