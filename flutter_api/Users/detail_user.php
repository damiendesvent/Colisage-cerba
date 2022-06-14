<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$code = $_POST['code'];
$password = $_POST['password'];

$sqlQuery = 'SELECT * FROM utilisateurs WHERE `CODE UTILISATEUR` = "'.$code.'" AND `MOT DE PASSE` = aes_encrypt("'.$password.'", "%C*F-JaNdRgUkGn2r5u8x/B?D(G+KbPe") AND SUPPRIMEE = 0';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

if ($result != false){
    $result['MOT DE PASSE'] = $password;
}


echo json_encode($result);
?>