<?php
header('Content-Type: application/json');
include '../db_cerba.php';

$backup = $_POST['file'];

$sqlQuery = 'SELECT Valeur from `constantes` WHERE Nom = "Emplacement des archives"';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();
$backupPath = $stmt -> fetch(PDO::FETCH_ASSOC);
try{
    $img_directory = str_replace('Backup_traca','',getcwd()).'Images/Backup/';
    if (!is_dir($img_directory)) {mkdir($img_directory);}
    if (is_file($backupPath['Valeur'].'/tracabilite_'.$backup.'.sql')) {
        $str = explode("\n" , shell_exec('wmic process where "name=\'mysqld.exe\'" get ExecutablePath'))[1];
        $mysqlPath = str_replace("mysqld.exe", '', $str);
        $mysqlPath = str_replace(' ', '', $mysqlPath);
        exec($mysqlPath.'mysql -u root -proot cerba < '.$backupPath['Valeur'].'/tracabilite_'.$backup.'.sql');
        $files = scandir($backupPath['Valeur'].'/tracabilite_'.$backup);
        for ($i = 2; $i < count($files); $i++) {
            copy($backupPath['Valeur'].'/tracabilite_'.$backup.'/'.$files[$i], $img_directory.$files[$i]);
        }
    }
    elseif (is_file($backupPath['Valeur'].'/tracabilite_'.$backup.'.sql.zip')) {
        $str = explode("\n" , shell_exec('wmic process where "name=\'mysqld.exe\'" get ExecutablePath'))[1];
        $mysqlPath = str_replace("mysqld.exe", '', $str);
        $mysqlPath = str_replace(' ', '', $mysqlPath);
        $zip = new ZipArchive;
        if ($zip->open($backupPath['Valeur'].'/tracabilite_'.$backup.'.sql.zip') == true) {
            $zip->extractTo($backupPath['Valeur'].'/');
            $zip->close();
            exec($mysqlPath.'mysql -u root -proot cerba < '.$backupPath['Valeur'].'/tracabilite_'.$backup.'.sql');
            $files = scandir($backupPath['Valeur'].'/tracabilite_'.$backup);
            for ($i = 2; $i < count($files); $i++) {
                copy($backupPath['Valeur'].'/tracabilite_'.$backup.'/'.$files[$i], $img_directory.$files[$i]);
            }
            unlink($backupPath['Valeur'].'/tracabilite_'.$backup.'.sql');
        }
        else {
            die;
        }
    }
    else {
        $files = scandir($img_directory);
        for ($i = 2; $i < count($files); $i++) {
                unlink($img_directory.$files[$i]);
        }
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