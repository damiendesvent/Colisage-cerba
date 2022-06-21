<?php
header('Content-Type: application/json; charset=utf-8');

include "../db_cerba.php";

$numberLimit = $_POST['limit'];
$order = $_POST['order'];
$isAscending = $_POST['isAscending'] == 'true' ? 'ASC' : 'DESC';
$delete = $_POST['delete'] == 'true' ? 1 : 0;

$search = array('À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü', 'Ý');
$replace = array('A', 'A', 'A', 'A', 'A', 'A', 'C', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'O', 'O', 'O', 'O', 'O', 'U', 'U', 'U', 'U', 'Y');

$order = str_replace($search,$replace,$order);


$sqlQuery = 'SELECT * FROM utilisateurs WHERE SUPPRIMEE = '.$delete.' ORDER BY `'.$order.'` '.$isAscending.' LIMIT '.$numberLimit;
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

for($i=0; $i<count($result); $i++){
    $result[$i]['MOT DE PASSE'] = '';
}

echo json_encode($result);