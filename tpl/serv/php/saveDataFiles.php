<?php

function isValidJSON($str) {
   global $decodedJson;
   $decodedJson = json_decode($str);
   return json_last_error() == JSON_ERROR_NONE;
}

$json_params = file_get_contents("php://input");

if (strlen($json_params) <= 0 || !isValidJSON($json_params)) { echo "Invalid JSON."; return; }

$s = "";
foreach ($decodedJson->data as $fileData) {
   $path = $fileData->path;
   $path2 = "../../".$path;
   $bytes = base64_decode($fileData->data);

   $s = "'".$path."': " . (string)stat($path2)["size"];
   $stream = fopen($path2, "wb");
   if ($stream == false) { $s .= "LOST."; continue; }
   $s .= " -> " . (string)fstat($stream)["size"];
   fwrite($stream, $bytes);
   $s .= " -> " . (string)fstat($stream)["size"];
   fclose($stream);
   $s .= " -> " . (string)stat($path)["size"]."\n";
}
if (strlen($s) > 0) echo "Files saved :\n".$s;
else echo "No files rewritten.";

?>