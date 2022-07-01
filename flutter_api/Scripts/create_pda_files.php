<?php
header('Content-Type: application/json');
include "../db_cerba.php";

$directory_path = 'C:/PDA_tracks/out'; //$_POST['directory_path'];

$accents_search     = array('á','à','â','ã','ª','ä','å','Á','À','Â','Ã','Ä','é','è',
'ê','ë','É','È','Ê','Ë','í','ì','î','ï','Í','Ì','Î','Ï','œ','ò','ó','ô','õ','º','ø',
'Ø','Ó','Ò','Ô','Õ','ú','ù','û','Ú','Ù','Û','ç','Ç','Ñ','ñ'); 

$accents_replace    = array('a','a','a','a','a','a','a','A','A','A','A','A','e','e',
'e','e','E','E','E','E','i','i','i','i','I','I','I','I','oe','o','o','o','o','o','o',
'O','O','O','O','O','u','u','u','U','U','U','c','C','N','n'); 

// Création du fichier COLFRE.txt avec les entêtes de feuilles de route :
$colfre_file = fopen($directory_path.'/COLFRE.txt','w');

$sql_colfre_query = 'SELECT * FROM `ENTETES FEUILLE DE ROUTE` WHERE SUPPRIMEE = 0 ORDER BY `ORDRE AFFICHAGE PDA`';
$stmt = $db -> prepare($sql_colfre_query);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

for ($i = 0; $i < count($result); $i++) {
    $content = str_pad($result[$i]['ORDRE AFFICHAGE PDA'], 4, '0',STR_PAD_LEFT).str_replace($accents_search, $accents_replace, $result[$i]['LIBELLE TOURNEE'])."\n";
    fwrite($colfre_file, $content);
}

fclose($colfre_file);


// Création du fichier COLFRD.txt avec les détails de feuilles de route :
$colfrd_file = fopen($directory_path.'/COLFRD.txt','w');

$sql_colfrd_query = 'SELECT `ENTETES FEUILLE DE ROUTE`.`ORDRE AFFICHAGE PDA`,
                            `DETAILS FEUILLE DE ROUTE`.`CODE AVANCEMENT`, 
                            `DETAILS FEUILLE DE ROUTE`.`CODE SITE`, 
                            `DETAILS FEUILLE DE ROUTE`.`HEURE ARRIVEE`, 
                            `SITES`.`LIBELLE SITE`, 
                            `DETAILS FEUILLE DE ROUTE`.`PASSAGE SUR APPEL`, 
                            `SITES`.`CP`, 
                            `SITES`.`VILLE`,
                            `SITES`.`ADRESSE`, 
                            `SITES`.`COMPLEMENT ADRESSE`, 
                            `DETAILS FEUILLE DE ROUTE`.`COMMENTAIRE` 
                            FROM `DETAILS FEUILLE DE ROUTE` 
                            JOIN `SITES` ON `DETAILS FEUILLE DE ROUTE`.`CODE SITE` = `SITES`.`CODE SITE`
                            JOIN `ENTETES FEUILLE DE ROUTE` ON `ENTETES FEUILLE DE ROUTE`.`CODE TOURNEE` = `DETAILS FEUILLE DE ROUTE`.`CODE TOURNEE`
                            WHERE `DETAILS FEUILLE DE ROUTE`.SUPPRIMEE = 0
                            ORDER BY `ENTETES FEUILLE DE ROUTE`.`ORDRE AFFICHAGE PDA`  ASC, `DETAILS FEUILLE DE ROUTE`.`CODE AVANCEMENT` ASC';

$stmt = $db -> prepare($sql_colfrd_query);
$stmt -> execute();
$result = $stmt -> fetchAll(PDO::FETCH_ASSOC);

for ($i = 0; $i < count($result); $i++) {
    $content = str_pad($result[$i]['ORDRE AFFICHAGE PDA'], 4, '0',STR_PAD_LEFT).
                str_pad($result[$i]['CODE AVANCEMENT'], 3, '0',STR_PAD_LEFT).
                str_pad($result[$i]['CODE SITE'], 4, '0',STR_PAD_LEFT).
                str_pad($result[$i]['HEURE ARRIVEE'], 5, '0', STR_PAD_LEFT).
                str_pad(str_replace($accents_search, $accents_replace, $result[$i]['LIBELLE SITE']), 35, ' ',STR_PAD_RIGHT).
                ($result[$i]['PASSAGE SUR APPEL'] == '1' ? 'O' : 'N').
                str_pad(str_replace($accents_search, $accents_replace, $result[$i]['ADRESSE']), 35, ' ',STR_PAD_RIGHT).
                str_pad(str_replace($accents_search, $accents_replace, $result[$i]['COMPLEMENT ADRESSE']), 35, ' ',STR_PAD_RIGHT).
                str_pad($result[$i]['CP'], 6, ' ',STR_PAD_RIGHT).
                str_pad(str_replace($accents_search, $accents_replace, $result[$i]['VILLE']), 29, ' ',STR_PAD_RIGHT).
                $result[$i]['COMMENTAIRE']."\n";
    fwrite($colfrd_file, $content);
}

fclose($colfrd_file);



