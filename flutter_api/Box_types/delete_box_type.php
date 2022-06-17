<?php
header('Content-Type: application/json, charset=utf-8');
include "../db_cerba.php";

$code = $_POST['code'];
$cancel = $_POST['cancel'] == 'true' ? 0 : 1;


$sqlQuery = 'UPDATE `type boite` SET `SUPPRIMEE` = "'.$cancel.'" WHERE `type boite`.`ACRONYME` = "'.$code.'"';
$stmt = $db -> prepare($sqlQuery);

$stmt -> execute();


