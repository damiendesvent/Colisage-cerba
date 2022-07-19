<?php
header('Content-Type: application/json');
include './src/fpdf.php';
include './src/barcode.php';

$codes = $_POST['codes'];
$libelles = $_POST['libelles'];

$codes = str_replace('[','',$codes);
$codes = str_replace(']','',$codes);
$codes = explode(', ', $codes);

$libelles = str_replace('[','',$libelles);
$libelles = str_replace(']','',$libelles);
$libelles = explode(', ', $libelles);

$x_padding = 66;
$x_margin = 14;
$y_padding = 38;
$y_margin = 26;

$pdf = new FPDF();
$pdf->AddPage();
$pdf->SetFont('Arial','B','9');

$x=0;
$y=0;

if (!is_dir('sites_barcodes')){
    mkdir('sites_barcodes');
}

if (is_file('label.pdf')){
    unlink('label.pdf');
}

for ($i=0;$i<count($codes);$i++) {
    if ($x == 3) {
        $y += 1;
        $x = 0;
    }
    if ($y == 7){
        $pdf->AddPage();
        $y = 0;
    }
    $text = sprintf("%04d",$codes[$i]);
    $path = './sites_barcodes/'.$text.'.png';
    barcode($path, $text, $size=25, $orientation, $code_type, true, $sizefactor);
    $libelle = strlen($libelles[$i]) > 20 ? substr($libelles[$i], 0, 17).'...' : $libelles[$i];
    $pdf->Text($x_margin + $x_padding*$x + 25 - strlen($libelle)*0.9, $y_margin + $y_padding*$y - 2, $libelle);
    $pdf->Image($path, $x_margin + $x_padding*$x, $y_margin + $y_padding*$y, 50);
    $x += 1;
}

$pdf->Output('label.pdf','f');

if (is_dir('sites_barcodes')) {
$files = glob('./sites_barcodes/*');
    foreach($files as $file) {
        if(is_file($file)){
            unlink($file);
        }
    }
}

if(is_dir('sites_barcodes')){
    rmdir('sites_barcodes');
}

readfile('label.pdf');

?>
