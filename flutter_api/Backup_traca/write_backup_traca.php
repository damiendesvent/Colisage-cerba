<?php
header('Content-Type: application/json');
include '../db_cerba.php';

$backup = $_POST['file'];

$sqlQuery = 'SELECT Valeur from `constantes` WHERE Nom = "Emplacement des sauvegardes"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$backupPath = $stmt -> fetch(PDO::FETCH_ASSOC);

try{
    if (is_file($backupPath['Valeur'].'/tracabilites/tracabilite_'.$backup.'.sql')) {
        $str = explode("\n" , shell_exec('wmic process where "name=\'mysqld.exe\'" get ExecutablePath'))[1];
        $mysqlPath = str_replace("mysqld.exe", '', $str);
        $mysqlPath = str_replace(' ', '', $mysqlPath);
        system($mysqlPath.'mysql -u root -proot cerba < '.$backupPath['Valeur'].'/tracabilites/tracabilite_'.$backup.'.sql');
    }
    else {
        $sqlQuery = 'TRUNCATE backup_tracabilite';
        $stmt = $db -> prepare($sqlQuery);
        $stmt -> execute();
    }
}
catch (Exception $e)
{
    echo 'error';
    die('Erreur : '.$e->getMessage());
}