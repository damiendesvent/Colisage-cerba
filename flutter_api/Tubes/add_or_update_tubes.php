<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$tube = $_POST['tube'];
$box = $_POST['box'];

$tube = substr($tube, 1, strlen($tube) - 2);
$tube = explode(',',$tube);
$tube = str_replace(' ','', $tube);

for ($i = 0; $i < count($tube); $i ++) {
    $sqlQuery = 'SELECT * FROM `tube` WHERE `CODE TUBE` = "'.$tube[$i].'"';
    $stmt = $db -> prepare($sqlQuery);
    $stmt -> execute();
    $result = $stmt -> fetch(PDO::FETCH_ASSOC);

    if (gettype($result) == 'boolean') {
        $sqlQuery = 'INSERT INTO `tube` (`code tube`, `code boite`) VALUES ("'.$tube[$i].'", "'.$box.'");';
        $stmt = $db -> prepare($sqlQuery);
        $result = $stmt -> execute();
    }
    else {
        $sqlQuery = 'UPDATE `tube` SET `CODE BOITE` = "'.$box.'" WHERE `CODE TUBE` = "'.$tube[$i].'"';
        $stmt = $db -> prepare($sqlQuery);
        $stmt -> execute();
    }
}