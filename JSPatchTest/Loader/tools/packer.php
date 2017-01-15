<?php 

const PRIVATE_KEY = <<<EOD
    -----BEGIN RSA PRIVATE KEY-----
    MIICXAIBAAKBgQDMPrkwMxpZwe+ypVR6I5uZ+NAnVSJI/fOAeq3DES7vQAUYZSV+
    zPT1JNtabFKApuN2HCI7ZRbRdXnwJK2kt9DRco6aB5zI9V+gkAjV/KLt8FtjFfzq
    GswjbhozTH3gkiyrWgJqp7s4XDz0F/wIoS/z/Skfay6ZuQOwqFLRvgJJQwIDAQAB
    AoGAFNMIWqu7Mg+d+t70gAeFY+uEfZ4mgr6xxxW7BbqIyIgEfPpDGmyXRS9e1hdZ
    Shi59F7l9pxV+UE7D4sN0U+UkLePAfdsYSGv4BjoPPEHynoBNyFGN+5vHpYGzXrS
    79oZYBBUmxTxhU5k0qjflqKQ0OzB/1PdtKBLGB4t0279+xECQQD4B9pYYVBj1iDX
    pAAzuA/W8s/ICqzEQOzYSOBGAUp9Wc8yxHVDpGQklHgfZgGTMbmWJzw0XawtKbuX
    eoiQ3EONAkEA0s63eCBmygv/WHK1tR7WXjp7JjQXAE1DG4ywNtH+8Iia9S5ZjjWL
    qHGBMW5ukUVHI2PPOHZW+wsOr5yIviSkDwJBAL7ZbA0tdCoeDc9gBjfFnYqL8429
    iQrJ2nTiPpAfVi31+RTbTk/qIpRzGasvVm7oiCEdt5mjqmRmBE6eno64rdECQGBb
    ZLlf9hv8h+bh5/S1975ydL/tp2XX6wi4sgMc0a8Ygdv4J689Am0oFKmHlLqKNA4V
    HS7tyKxPTZMvtcFT9jkCQFnk9brgSYj1GAOQ3BRN2NfkqaQ1RrfQfk4lNHcfu6ld
    Qr+rZegodO9rYyEeZkaSr2Q+gMjmHOc2xw2yWlTr908=
    -----END RSA PRIVATE KEY-----
EOD;

$files = "";
$zipFile = "script.zip";
$finalFile = "v1";
for ($i = 1; $i < count($argv); $i ++) {
    if ($argv[$i] == '-o') {
        $finalFile = $argv[$i + 1];
        break;
    }
    $files .= $argv[$i] . " ";
}

if (!empty($files)) {

    //compress files
    echo system("zip $zipFile $files"); 

    //get and encrypt zip file's md5
    $zipFileMD5 = md5_file($zipFile);
    $private_key = openssl_pkey_get_private(PRIVATE_KEY);
    $ret = openssl_private_encrypt($zipFileMD5, $encrypted, $private_key);

    if (!$ret || empty($encrypted)) {
        unlink($zipFile);
        echo "fail to encrypt file md5";
    }

    $md5File = "key";
    file_put_contents($md5File, $encrypted);

    //pack script zip file and md5 file to final zip file
    echo system("zip $finalFile $zipFile $md5File"); 

    unlink($md5File);
    unlink($zipFile);
}
