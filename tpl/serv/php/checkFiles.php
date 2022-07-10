<?php

function isValidJSON($str) {
   global $decodedJson;
   $decodedJson = json_decode($str);
   return json_last_error() == JSON_ERROR_NONE;
}

$json_params = file_get_contents("php://input");

if (strlen($json_params) <= 0 || !isValidJSON($json_params)) { echo "Invalid JSON."; return; }

$changedFiles = array() ;
foreach ($decodedJson->files as $file) {
	$filePath = $file->path;
	if (!file_exists("../../res/".$filePath)) continue;
	$fileMTime = $file->mTime;
	
	$currMTime = stat("../../res/".$filePath)["mtime"];
	if ($currMTime > $fileMTime) $changedFiles[$filePath] = $currMTime;
}
echo json_encode($changedFiles);

?>