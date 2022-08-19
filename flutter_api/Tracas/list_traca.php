<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";

$table = $_POST['backup'] == 'true' ? '`backup_tracabilite`' : '`tracabilite`';
$numberLimit = $_POST['limit'];
$order = $_POST['order'];
$isAscending = $_POST['isAscending'] == 'true' ? 'ASC' : 'DESC';

$search = array('À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü', 'Ý');
$replace = array('A', 'A', 'A', 'A', 'A', 'A', 'C', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'O', 'O', 'O', 'O', 'O', 'U', 'U', 'U', 'U', 'Y');

$order = str_replace($search,$replace,$order);

$sqlQuery = 'SELECT '.$table.'.*,`entetes feuille de route`.`LIBELLE TOURNEE`, `sites`.`LIBELLE SITE` 
            FROM '.$table.' 
            LEFT JOIN `entetes feuille de route` ON COALESCE('.$table.'.`CODE TOURNEE`,0) = `entetes feuille de route`.`CODE TOURNEE` 
            LEFT JOIN `sites` ON '.$table.'.`CODE SITE` = `sites`.`CODE SITE` ORDER BY `'.$order.'` '.$isAscending.', '.$table.'.`DATE HEURE ENREGISTREMENT` DESC LIMIT '.$numberLimit;
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);
