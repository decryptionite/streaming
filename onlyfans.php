
<html>
<?php

// submit code
$embedchk = $_GET['username'] ?? '';
if (empty($_GET['username'])) {
	echo"
	<head>
	</head>
	<body>
		<form method='post'>
			username:
			<input type='text' name='username'></input>
			<br />
			bio: <br />
			<input type='text' name='bio'></input>
			<br />
			<input type='submit' name='submitted' value='submit'></input>
		</form>
	</body>
	";
	
	if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['submitted'])) {
		$username = strtolower($_POST['username']) ?? '';
		$bio = $_POST['bio'] ?? '';
		
		if (empty($username) && empty($bio)) {
			echo'please submit valid inputs';
			return;
		}
		
		if (!preg_match('/^[A-Za-z0-9._-]+$/',$username)) {
			echo'you can only use a-Z, 0-9, ._-';
			return;
		}
		
		$db = new SQLite3('onlyfans.db');
		// init just in case
		$db->exec("CREATE TABLE IF NOT EXISTS creators (
			username TEXT PRIMARY KEY,
			bio TEXT NOT NULL);
		");
		// chk if name exists
		$chk1 = $db->prepare('SELECT username FROM creators WHERE username=:username LIMIT 1');
		$chk1->bindValue(':username',$username,SQLITE3_TEXT);
		$result = $chk1->execute();
		$row = $result->fetchArray();
		if (!empty($row)) {
			echo'name already added';
		} else {
			$create_stmt = $db->prepare("INSERT INTO creators (username, bio)
				VALUES (:username, :bio);
			");
			$create_stmt->bindValue(':username',$username,SQLITE3_TEXT);
			$create_stmt->bindValue(':bio',$bio,SQLITE3_TEXT);
			$created = $create_stmt->execute();
			if ($created) {
				echo'name added';
			}
		}
	}
} else {
	$username = $_GET['username'];
	$db = new SQLite3('onlyfans.db');
	$lookup = $db->prepare('SELECT username, bio FROM creators WHERE username=:username');
	$lookup->bindValue(':username',strtolower($username),SQLITE3_TEXT);
	$result1 = $lookup->execute();
	$row = $result1->fetchArray();
	if (!empty($row)) {
		$bio = $row['bio'];
		echo"
		<head>
			<meta property=og:image content=https://static2.onlyfans.com/static/prod/f/202512191636-69d7d24c47/images/of-logo-b.jpg>
			<meta property=og:image:width content=1200>
			<meta property=og:image:height content=1200>
			<meta property='og:site_name' content='OnlyFans' />
			<meta property=og:type content=website>
			<meta name=msapplication-TileColor content=#00aff0>
			<meta name=msapplication-navbutton-color content=#00aff0>
			<meta name=theme-color content=#00aff0>
		";
		echo'<meta property="og:title" content="'.$username.'\'s Profile - OnlyFans">';
		echo'<meta property="og:description" content="'.htmlspecialchars($row['bio']).'">';
	}
}
?>
</html>