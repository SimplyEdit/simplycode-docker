<?php
	ini_set('display_errors',1);

	require_once('http.php');
	require_once('filesystem.php');
	
	filesystem::basedir(dirname(__DIR__).'/www/api/data');

	filesystem::allow('/','.*');
/*
	filesystem::check('put','/', function($filename, $realfile) {
		$contents = file_get_contents($realfile);
		$result = json_decode($contents);
		if ($result === null) {
			throw new \Exception('Invalid JSON',1);
		}
		return true;			
	});
*/
/*
	filesystem::check('put','/',function($filename, $realfile) {
		if (preg_match('/^\{?[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}\}?$/', $filename)) {
			return true;
		}
		throw new \Exception('Invalid ID');
	});
*/