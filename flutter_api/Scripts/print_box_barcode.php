<?php
header('Content-Type: application/json');
include './src/fpdf.php';
include './src/barcode.php';
include '../db_cerba.php';


$start = (int) $_POST['start'];
$stop = (int) $_POST['stop'];
$acronyme = $_POST['acronyme'];
$libelle = $_POST['libelle'];
$createBoxes = $_POST['createBoxes'] == 'true';

$x_padding = 66;
$x_margin = 14;
$y_padding = 38;
$y_margin = 26;

$pdf = new FPDF();
$pdf->AddPage();
$pdf->SetFont('Arial','B','10');

$x=0;
$y=0;

if (!is_dir('barcodes')){
    mkdir('barcodes');
}

if (is_file('output.pdf')){
    unlink('output.pdf');
}

for ($i=$start;$i<=$stop;$i++) {
    if ($x == 3) {
        $y += 1;
        $x = 0;
    }
    if ($y == 7){
        $pdf->AddPage();
        $y = 0;
    }
    $text = 'B'.$acronyme.(string)sprintf("%05d",$i);
    $path = './barcodes/'.$text.'.png';
    barcode($path, $text, $size=40, $orientation, $code_type, true, $sizefactor );
    $pdf->Text($x_margin + $x_padding*$x + 25 - strlen($libelle), $y_margin + $y_padding*$y - 2, $libelle);
    $pdf->Image($path, $x_margin + $x_padding*$x, $y_margin + $y_padding*$y, 50);
    $x += 1;

    //cette partie insert les boites créées dans la table dédiée si le paramètre createBoxes vaut true
    if ($createBoxes) {
        $sqlQuery = 'INSERT INTO `boite` (`code boite`, `type boite`) VALUES ("'.$text.'", "'.$acronyme.'")';
        $stmt = $db -> prepare($sqlQuery);
        $stmt -> execute();
    }
}

$pdf->Output('output.pdf','f');

if (is_dir('barcodes')) {
$files = glob('./barcodes/*');
    foreach($files as $file) {
        if(is_file($file)){
            unlink($file);
        }
    }
}

if(is_dir('barcodes')){
    rmdir('barcodes');
}

readfile('output.pdf');

?>
