<?php
function ErrMsg($msg) {
	echo "<p><span class=\"err\">" . $msg . "</span></p>\n";
}

function IpToInt ($ip) {
	// Преобразование IP адреса в число
	$m = preg_split ("/\./", $ip);
	$b = 0;
	$s = false;
	if ($m[0] > 127) {
		$s = true;
		$m[0] -= 127;
	}
	for ($a=0; $a<4; $a++) {
		$c = (int) $m[$a];
		$b = ($b << 8) + $c;
	}
	$r = (float) $b;
	if ($s)
		$r = (float) $b + 2130706432;
	return $r;
}

function CheckAddr ($mip, $msk) {
	// Удалить управляющие символы ASCII из начала и конца (от 0 до 32 включительно),
	// убрать пробелы из строки и разбить на элементы (делитель ",")
	$mas = preg_split ("/\,/", str_replace(' ','', trim($msk, "\x00..\x20")));

	// Проверяем адрес на соответствие любому из условий
	$res = false;
	for ($a=0; $a<count($mas); $a++) {
		if (strlen($mas[$a]) == 0) // Пропустить пустые строки массива
			continue;
		$inv = $mas[$a]{0} == "!"; // Проверить на отрицание условия
		if (strpos($mas[$a], "-") !== false) { // Есть диапазон от и до
			$pos = strpos($mas[$a], "-");
			if ($inv)
				$a0 = substr($mas[$a], 1, $pos - 1);
			else
				$a0 = substr($mas[$a], 0, $pos);
			$a1 = substr($mas[$a], $pos + 1, strlen($mas[$a]) - $pos - 1);

			// Преобразование к числовому значению
			$bm = IpToInt($mip);
			$b0 = IpToInt($a0);
			$b1 = IpToInt($a1);

			// Проверить вхождения IP в текущий диапазон
			$res = ($b0 <= $bm) && ($bm <= $b1);
		} elseif (strpos($mas[$a], "/") !== false) { // Есть признак маски адреса
			$pos = strpos($mas[$a], "/");
			if ($inv)
				$a0 = substr($mas[$a], 1, $pos - 1);
			else
				$a0 = substr($mas[$a], 0, $pos);
			$a1 = substr($mas[$a], $pos + 1, strlen($mas[$a]) - $pos - 1);

			// Преобразование к числовому значению
			$b1 = (int) $a1;
			$bm = ((int) IpToInt($mip)) >> (32 - $b1);
			$b0 = ((int) IpToInt($a0)) >> (32 - $b1);

			// Проверить вхождения IP в текущий диапазон
			$res = $bm == $b0;
		} else { // Просто сравнение
			$res = $mip == $mas[$a];
		}
		if ($inv)
			$res = !$res;
		if ($res)
			$a = count($mas);
	}
	return $res;
}

// Класс для доступа к БД
class MyDB {
	var $dbh;
	var $dbr = 0;
	function __construct ($host, $uname, $upass, $base) {
		$ip = "0";
		$this->dbh = mysqli_connect($host, $uname, $upass, $base);
		if (!$this->dbh) {
			if (array_key_exists('REMOTE_ADDR', $_SERVER)) if (isset($_SERVER['REMOTE_ADDR']))
				$ip = $_SERVER['REMOTE_ADDR']; # IP адрес клиента
			if (strcmp($ip, "192.168.3.2") == 0) {
				ErrMsg("Error: Ошибка подключения к базе данных: " . mysqli_connect_error());
			} else {
				echo "\n<!-- Ошибка подключения к базе данных -->\n";
			}
		} else
			mysqli_query($this->dbh, "SET NAMES utf8");
	}
	function __destruct () {
		if ($this->dbh) {
			mysqli_close($this->dbh);
		}
	}
	function DoQuery ($query) {
		$this->dbr = mysqli_query($this->dbh, $query);
		return $this->dbr;
	}
	function FetchRow () {
		$dat = mysqli_fetch_row($this->dbr);
		return $dat;
	}
}
?>