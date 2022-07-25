<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$tube = $_POST['tube'];
$box = $_POST['box'];
$site = $_POST['site'];


$sqlQuery = 'SELECT * FROM `tube` WHERE `CODE TUBE` = "'.$tube.'"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

if (gettype($result) == 'boolean') {
    $sqlQuery = 'INSERT INTO `tube` (`code tube`, `code boite`, `code site`) VALUES ("'.$tube.'", "'.$box.'", (SELECT `CODE SITE` FROM `sites` WHERE `LIBELLE SITE` = "'.$site.'" LIMIT 1));';
    $stmt = $db -> prepare($sqlQuery);
    $result = $stmt -> execute();
}
else {
    $sqlQuery = 'UPDATE `tube` SET `CODE BOITE` = "'.$box.'", `CODE SITE` = (SELECT `CODE SITE` FROM `sites` WHERE `LIBELLE SITE` = "'.$site.'" LIMIT 1) WHERE `CODE TUBE` = "'.$tube.'"';
    $stmt = $db -> prepare($sqlQuery);
    $stmt -> execute();
}
