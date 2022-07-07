<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$field = '`'.$_POST['field'].'`';
$advancedField = '`'.$_POST['advancedField'].'`';
$secondAdvancedField = '`'.$_POST['secondAdvancedField'].'`';
$searchText = $_POST['searchText'];
$advancedSearchText = $_POST['advancedSearchText'];
$secondAdvancedSearchText = $_POST['secondAdvancedSearchText'];
$numberLimit = $_POST['limit'];
$order = $_POST['order'];
$isAscending = $_POST['isAscending'] == 'true' ? 'ASC' : 'DESC';

$search = array('À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü', 'Ý');
$replace = array('A', 'A', 'A', 'A', 'A', 'A', 'C', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'O', 'O', 'O', 'O', 'O', 'U', 'U', 'U', 'U', 'Y');

$field = str_replace($search,$replace,$field);
$advancedField = str_replace($search,$replace,$advancedField);
$secondAdvancedField = str_replace($search, $replace, $secondAdvancedField);
$order = str_replace($search,$replace,$order);

$search = strpos($searchText, '__') === false ? ' LIKE "%'.$searchText.'%"' : ' BETWEEN "'.explode('__',$searchText)[0].'" AND "'.explode('__', $searchText)[1].'"';
$advancedSearch = strlen($advancedSearchText) > 0 ? ' AND '.$advancedField.(strpos($advancedSearchText, '__') === false ? ' LIKE "%'.$advancedSearchText.'%"' : ' BETWEEN "'.explode('__',$advancedSearchText)[0].'" AND "'.explode('__', $advancedSearchText)[1].'"') : '';
$secondAdvancedSearch = strlen($secondAdvancedSearchText) > 0 ? ' AND '.$secondAdvancedField.(strpos($secondAdvancedSearchText, '__') === false ? ' LIKE "%'.$secondAdvancedSearchText.'%"' : ' BETWEEN "'.explode('__',$secondAdvancedSearchText)[0].'" AND "'.explode('__', $secondAdvancedSearchText)[1].'"') : '';

$sqlQuery = 'SELECT * FROM tracabilite WHERE '.$field.$search.$advancedSearch.$secondAdvancedSearch.' ORDER BY `'.$order.'` '.$isAscending.' LIMIT '.$numberLimit;
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);