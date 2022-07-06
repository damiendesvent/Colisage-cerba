<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$ip = $_SERVER['REMOTE_ADDR'];

$sqlQuery = 'SELECT `LIBELLE SITE` FROM SITES 
            JOIN `correspondance ip` ON `correspondance ip`.`SITE` = `sites`.`CODE SITE` 
            WHERE `correspondance ip`.`PREFIXE IP` LIKE substring("'.$ip.'",1, LENGTH(`correspondance ip`.`PREFIXE IP`))';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetch(PDO::FETCH_ASSOC);

$site = $result == false ? '' : $result['LIBELLE SITE'];

$array = array('ip' => $ip,
            'site' => $site);

echo json_encode($array);