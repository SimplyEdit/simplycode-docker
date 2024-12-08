<?php
	ini_set('display_errors', 1);
	ini_set('display_startup_errors', 1);
	error_reporting(E_ALL);
	require_once('../../lib/config.php');

	$request  = http::request();
	$requestTarget = $request['target'];
	$requestTarget = preg_replace("/^\/api/", "", $requestTarget);
	$path     = filesystem::path($requestTarget);
	$dirname  = dirname($path);
	$filename = basename($path);

	function guid() {
		return sprintf('%04X%04X-%04X-%04X-%04X-%04X%04X%04X', mt_rand(0, 65535), mt_rand(0, 65535), mt_rand(0, 65535), mt_rand(16384, 20479), mt_rand(32768, 49151), mt_rand(0, 65535), mt_rand(0, 65535), mt_rand(0, 65535));
	}
	function tagId() {
		return sprintf('%03d-%03d', mt_rand(0, 999), mt_rand(0, 999));
	}

	function readRecursive($path) {
		$dirname  = dirname($path);
		$filename = basename($path);
		if (filesystem::is_dir($path)) {
			$files = filesystem::scandir($path);
			$files = array_filter($files, function($file) {
				if ($file == '.' || $file == '..') {
					return false;
				}
				return true;
			});
			$result = [];
			foreach ($files as $filename) {
				if (filesystem::exists($path . '/' . $filename . '/meta')) {
					$data = json_decode(filesystem::read($path . '/' . $filename, "meta"), true);
				}
				if (filesystem::exists($path . '/' . $filename . '/meta.json')) {
					$data = json_decode(filesystem::read($path . '/' . $filename, "meta.json"), true);
				}

				$data['id'] = $filename;
				$data['ctime'] = filesystem::ctime($path, $filename);
				$data['ctime-human'] = date("c", $data['ctime']);
				$data['contents'] = readRecursive($path . "/" . $filename);
				$result[] = $data;
			}
			return $result;
		} else {
			return filesystem::read($dirname, $filename);
		}
	}

	function deleteRecursive($path) {
		$dirname  = dirname($path);
		$filename = basename($path);
		if (filesystem::is_dir($path)) {
			$files = filesystem::scandir($path);
			$files = array_filter($files, function($file) {
				if ($file == '.' || $file == '..') {
					return false;
				}
				return true;
			});
			foreach ($files as $file) {
				deleteRecursive($path . "/" . $file);
			}
			filesystem::delete($dirname, $filename);
		} else {
			filesystem::delete($dirname, $filename);
		}
	}

	try {
		switch($request['method']) {
			case 'OPTIONS':
				output('ok',200);
			break;
			case 'GET':
				if (filesystem::exists($dirname . "/" . $filename)) {
					$result = readRecursive($path);
					output($result, 200);
				} else {
					filenotfound($path);
				}
			break;
			case 'POST':
				if (filesystem::exists($path)) {
					if (filesystem::is_dir($path)) {
						$exists = true;
						while ($exists) {
							$newId = tagId();
							$newFilename = $newId;
							$exists = filesystem::exists($path . $newFilename);
						}

						// at this point, we are sure that the generated filename does not yet exists, so we can write it;
						filesystem::put($path, $newFilename);
						output($newId, 200);
					}
				}
			break;
			case 'PUT':
				if (filesystem::put($dirname, $filename)) {
					output('ok',200);
				} else {
					error(new \Exception("unexpected result from write",501));
				}
			break;
			case 'DELETE':
				if (filesystem::exists($path) || filesystem::exists($dirname . "/" . $filename)) {
					deleteRecursive($path);
					output("deleted", 200);
				} else {
					filenotfound($path);
				}
			break;
		}
	} catch( \Exception $e) {
		error($e);
	}

	function output($data, $status) {
		http::response($status, $data);		
	}

	function error($e) {
		output(["error" => $e->getCode(), "message" => $e->getMessage()], 501);		
	}

	function filenotfound($path) {
		output(["error" => 404, "message" => "File not found"], 404);
	}
