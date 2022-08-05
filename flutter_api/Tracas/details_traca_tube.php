<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$tube = $_POST['tube'];

$sqlQuery = '(SELECT `tracabilite`.`UTILISATEUR`, `tracabilite`.`BOITE`, `tracabilite`.`ACTION`, `tracabilite`.`DATE HEURE ENREGISTREMENT` AS `ENREGISTREMENT`, `tracabilite`.`DATE HEURE SYNCHRONISATION` AS `SYNCHRONISATION`, `tracabilite`.`CODE ORIGINE`, `tracabilite`.`CODE VOITURE`, `tracabilite`.`COMMENTAIRE`, `sites`.`LIBELLE SITE` AS `SITE`, `entetes feuille de route`.`LIBELLE TOURNEE` AS `TOURNEE` FROM `tracabilite` 
            LEFT JOIN `entetes feuille de route` ON `tracabilite`.`CODE TOURNEE` = `entetes feuille de route`.`CODE TOURNEE`
            LEFT JOIN `sites` ON `tracabilite`.`CODE SITE` = `sites`.`CODE SITE`
            WHERE `tracabilite`.`TUBE` = "'.$tube.'" 
            ORDER BY `tracabilite`.`DATE HEURE SYNCHRONISATION` DESC 
            LIMIT 1) 
            UNION 
            (SELECT `tracabilite`.`UTILISATEUR`, `tracabilite`.`BOITE`, `tracabilite`.`ACTION`, `tracabilite`.`DATE HEURE ENREGISTREMENT` AS `ENREGISTREMENT`, `tracabilite`.`DATE HEURE SYNCHRONISATION` AS `SYNCHRONISATION`, `tracabilite`.`CODE ORIGINE`, `tracabilite`.`CODE VOITURE`, `tracabilite`.`COMMENTAIRE`, `sites`.`LIBELLE SITE` AS `SITE`, `entetes feuille de route`.`LIBELLE TOURNEE` AS `TOURNEE` FROM `tracabilite` 
            LEFT JOIN `entetes feuille de route` ON `tracabilite`.`CODE TOURNEE` = `entetes feuille de route`.`CODE TOURNEE`
            LEFT JOIN `sites` ON `tracabilite`.`CODE SITE` = `sites`.`CODE SITE`
            WHERE (BOITE = (SELECT BOITE FROM tracabilite 
                        WHERE TUBE = "'.$tube.'" 
                        ORDER BY `DATE HEURE SYNCHRONISATION` DESC 
                        LIMIT 1) 
                AND ACTION = "RAM")
            ORDER BY `DATE HEURE SYNCHRONISATION` DESC LIMIT 1)
            UNION
            (SELECT `tracabilite`.`UTILISATEUR`, `tracabilite`.`BOITE`, `tracabilite`.`ACTION`, `tracabilite`.`DATE HEURE ENREGISTREMENT` AS `ENREGISTREMENT`, `tracabilite`.`DATE HEURE SYNCHRONISATION` AS `SYNCHRONISATION`, `tracabilite`.`CODE ORIGINE`, `tracabilite`.`CODE VOITURE`, `tracabilite`.`COMMENTAIRE`, `sites`.`LIBELLE SITE` AS `SITE`, `entetes feuille de route`.`LIBELLE TOURNEE` AS `TOURNEE` FROM `tracabilite` 
            LEFT JOIN `entetes feuille de route` ON `tracabilite`.`CODE TOURNEE` = `entetes feuille de route`.`CODE TOURNEE`
            LEFT JOIN `sites` ON `tracabilite`.`CODE SITE` = `sites`.`CODE SITE`
            WHERE (BOITE = (SELECT BOITE FROM tracabilite 
                        WHERE TUBE = "'.$tube.'" 
                        ORDER BY `DATE HEURE SYNCHRONISATION` DESC 
                        LIMIT 1) 
                AND ACTION = "DEP")
            ORDER BY `DATE HEURE SYNCHRONISATION` DESC LIMIT 1)';
$stmt = $db -> prepare($sqlQuery);
$stmt -> execute();

$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);