<?php
header('Content-Type: application/json; charset=utf-8');
include "../db_cerba.php";


date_default_timezone_set('Europe/Paris');
$date = date('d-m-y_H-i-s');
try {
    $sqlQuery = "(select 'Code Tracabilite','Utilisateur','Code Tournee','Libelle Tournee','Code Site','Libelle Site','Boite','Tube','Action','Enregistrement','Synchronisation','Origine','Code Voiture','Photo','Signature','Commentaire')
                union 
                (select `CODE TRACABILITE`,`UTILISATEUR`,IFNULL(`tracabilite`.`CODE TOURNEE`, ''),IFNULL(`entetes feuille de route`.`LIBELLE TOURNEE`, ''),`tracabilite`.`CODE SITE`,IFNULL(`sites`.`LIBELLE SITE`,''),IFNULL(`BOITE`, ''),IFNULL(`TUBE`, ''),`ACTION`,`DATE HEURE ENREGISTREMENT`,`DATE HEURE SYNCHRONISATION`,`CODE ORIGINE`,IFNULL(`CODE VOITURE`, ''),IFNULL(`PHOTO`, ''),IFNULL(`SIGNATURE`, ''),IFNULL(`tracabilite`.`COMMENTAIRE`, '') 
                 from `tracabilite` 
                 LEFT JOIN `entetes feuille de route` ON COALESCE(`tracabilite`.`CODE TOURNEE`,0) = `entetes feuille de route`.`CODE TOURNEE`
                 LEFT JOIN `sites` ON `tracabilite`.`CODE SITE` = `sites`.`CODE SITE`
                 into outfile 'C:/Serveur_colisage/htdocs/$date.csv' 
                 fields enclosed by '\"'
                 terminated by ';' 
                 escaped by '\"' 
                 lines terminated by'\r\n')";
    $stmt = $db -> prepare($sqlQuery);
    $stmt -> execute(); 
    
}
    
catch (Exception $e)
{
    die('Erreur : '.$e->getMessage());
}

