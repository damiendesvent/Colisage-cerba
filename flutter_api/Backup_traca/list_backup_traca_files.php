<?php
header('Content-Type: application/json');
include '../db_cerba.php';

$sqlQuery = 'SELECT Valeur from `constantes` WHERE Nom = "Emplacement des sauvegardes"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$backupPath = ($stmt -> fetch(PDO::FETCH_ASSOC))['Valeur'].'/tracabilites/';

$backup_files = scandir($backupPath, SCANDIR_SORT_DESCENDING);

$files = array();
for ($i = 0; $i < count($backup_files) - 2; $i++) {
    $file = str_replace('tracabilite_', '', $backup_files[$i]);
    $file = str_replace('.sql', '', $file);
    array_push($files, $file);
}

echo json_encode($files);