<?php
header("Content-Type: application/json");


$image = $_POST['image'];
$backup = $_POST['backup'];

$url_image = $backup == 'true' ? "Images/Backup/$image" : "Images/$image";
$url_prefix = "http://$_SERVER[HTTP_HOST]/flutter_api/";

if (file_exists('../'.$url_image.'.jpg')) {
    echo json_encode($url_prefix.$url_image.'.jpg');
}

if (file_exists('../'.$url_image.'.jpeg')) {
    echo json_encode($url_prefix.$url_image.'.jpeg');
}

if (file_exists('../'.$url_image.'.png')) {
    echo json_encode($url_prefix.$url_image.'.png');
}