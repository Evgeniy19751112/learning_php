<!DOCTYPE html>
<html>

<head>
	<META http-equiv=Content-Type content="text/html; charset=utf-8">
	<META name="author" Content="Тявкин Евгений Николаевич">
	<META name="copyright" Content="Тявкин Евгений Николаевич">
	<META name="description" CONTENT="Домашняя страница Муниципального учреждения Управление финансов администрации Тындинского района. Для локального использования">
	<META name="keywords" CONTENT="домашняя страница, муниципальное учреждение, управление финансов, МУ Управление финансов района">
	<link rel="stylesheet" href="/main.css" type="text/css">
	<link rel="shortcut icon" href="/favicon.ico">
	<title>Ссылки на сайты для сотрудников МУ Управление финансов района</title>
	<script type="text/javascript" src="/main.js"></script>
</head>

<body>
<!-- Закладки в верхней части, которые всегда отображаются -->
<div id="headerMain"><div id="header"><table width="1220" height="60" class="tblhead" align="center"><tr><td>
	<table height="56" width="1200" class="tblheadmenu">
		<tr>
			<td><a href="#group2">Органы исполнительной власти</a></td>
			<td><a href="#group3">Госуслуги</a></td>
			<td><a href="#group4">Официальные сайты Российской Федерации</a></td>
			<td><a href="#group5">ФНС, ПФР, Статистика</a></td>
		</tr>
		<tr>
			<td><a href="#group6">Кредитно-финансовые организации</a></td>
			<td><a href="#group7">Удостоверяющие центры</a></td>
			<td><a href="#group8">Поисковые и почтовые системы</a></td>
			<td><a href="#group9">Прочие полезные информационные ресурсы</a></td>
		</tr>
	</table>
</td></tr></table></div></div>

<!-- Основная часть станицы -->
<table width="1220" class="tblvnesh" align="center">
	<tr><td width="850">
		<!-- Динамическая часть страницы (Начало) -->
		<H1>Закладки</H1><HR>
<?php
require_once 'mylib.php';

// Класс для формирования таблицы
class MyTbl {
# Глобальные переменные
	var $dbh;
	var $sth;
	var $stb;
	var $stg;
	var $c0 = "#BEE6FF";
	var $c1 = "#DCF2FF";
	var $imgdir = "/home/admins/html/img"; # путь до каталога с изображениями эмблем
	var $uip = "127.0.0.1"; # IP адрес клиента
	var $uun = ""; # Пользовательское имя
	var $uid = 0; # Пользовательский ID
	var $dbc;

	function __construct () {
		if (array_key_exists('REMOTE_ADDR', $_SERVER)) if (isset($_SERVER['REMOTE_ADDR']))
			$this->uip = $_SERVER['REMOTE_ADDR']; # IP адрес клиента
		$this->dbc = new MyDB('localhost', 'uprfinusr', 'pGiRY2dOjaZGVOcQ', 'uprfin');
	} // __construct

	function __destruct () {
		unset($this->dbc);
	} // __destruct

	function CheckUser () {
		# Определяем пользователя (новый/старый)
		$res = true;
		$mas = preg_split ("/\./", $this->uip);
		$qa = "";
		$qb = "SELECT * FROM users WHERE";

		# Формируем запрос к БД
		for ($c=0; $c<=3; $c++)
			$qb = $qb . (($c) ? " AND " : " (id>0 AND ") . "g$c='" . $mas[$c] . "'";
		$qb = $qb . ")";

		# Получаем данные
		if ($this->dbc->DoQuery($qb)) {
			$u = $this->dbc->FetchRow();
			if (!isset($u)) {
				# Добавить пользователя в БД (раз его нет)
				$qa = "(NULL, CURRENT_TIMESTAMP,";
				for ($c=0; $c<=3; $c++)
					$qa = "$qa '" . $mas[$c] . "',";
				if (array_key_exists('REMOTE_HOST', $_SERVER)) if (isset($_SERVER['REMOTE_HOST']))
					$this->uun = $_SERVER['REMOTE_HOST'];
				if (!$this->uun)
					$this->uun = $this->uip;
				if (!$this->dbc->DoQuery("INSERT INTO users (`id`, `dt`, `g0`, `g1`, `g2`, `g3`, `un`, `country`, `rem`) VALUES $qa '" . $this->uun . "', '', '')")) # готовим запрос
					ErrMsg("Ошибка добавления нового пользователя $this->uun в БД.");
				unset($u);
				if ($this->dbc->DoQuery($qb))
					$u = $this->dbc->FetchRow();
				if (!isset($u)) {
					ErrMsg("Ошибка при контрольном получении данных пользователя $this->uip из БД.");
					$res = false;
				}
			}
		} else {
			ErrMsg("Ошибка при получении данных пользователя " . $this->uip . " из БД.");
			$res = false;
		}
		$this->uid = $u[0];
		$this->uun = $u[6];
		if (!$this->uun)
			$this->uun = $this->uip;

		# Делаем пометку о посещаемости
		$this->dbc->DoQuery("INSERT INTO countu (`id`, `dt`, `idu`) VALUES (NULL, CURRENT_TIMESTAMP, '" . $this->uid . "')"); # готовим запрос

		# Готово. Вернуть результат
		return $res;
	} // CheckUser

	function CheckDostup () {
		# Получить список его блокировок (блокировок на ресурсы все для пользователей)
		$res = false;
		if ($this->dbc->DoQuery("SELECT id, deny, alow FROM dostup WHERE (idg=0 AND idr=0) ORDER BY id ASC")) { # запрос на полный доступ
			$rn = mysqli_num_rows($this->dbc->dbr);
			$dd = "";
			$da = "";
			for ($i=0; $i<$rn; $i++) {
				$grp = $this->dbc->FetchRow();
				if ($grp[1])
					$dd .= "," . $grp[1];
				if ($grp[2])
					$da .= "," . $grp[2];
			}
			if ($dd)
				$res = !CheckAddr($this->uip, $dd);
			if ($da)
				$res = CheckAddr($this->uip, $da);
		}
		return $res;
	} // CheckDostup

	function MakeTable () {
		# Получить список групп (разделов)
		$res = true;
		
		if ($this->dbc->DoQuery("SELECT tr.*, td.deny, td.alow, td.idr FROM razdely AS tr LEFT JOIN dostup AS td ON td.idg=tr.id WHERE (tr.id>0) ORDER BY tr.id ASC")) {
			# Занести даные в массив
			$grn = mysqli_num_rows($this->dbc->dbr);
			for ($i=0; $i<$grn; $i++)
				$grp[$i] = $this->dbc->FetchRow();

			# Перебрать все группы и сформировать список ссылок
			$qa = "";
			$qb = "";
			$img = "";
			$izb = true;
			$idt = 1;
			for ($i=0; $i<$grn; $i++) {
				$refg = $grp[$i];

				// Проверка на доступ к группе (4=deny; 5=alow)
				if (strlen($refg[4]) && !$refg[6]) {
					if (CheckAddr($this->uip, $refg[4])) {
						continue;
					}
				}
				if (strlen($refg[5]) && !$refg[6]) {
					if (!CheckAddr($this->uip, $refg[5])) {
						continue;
					}
				}

				# Получаем список ресурсов для распределения по группам
				$cr = $refg[0];
				if ($izb) {
					$this->dbc->DoQuery("SELECT rr.id, ss.poryadok, rr.url, rr.urlrem, rr.imgsrc, rr.imgtitle, ss.dostup FROM sortirovka as ss, resursi as rr WHERE (rr.id>0 AND ss.idu=$this->uid AND ss.idr=rr.id AND ss.dostup>0) ORDER BY ss.poryadok ASC"); # готовим запрос
					$izb = false;
				} else {
					$this->dbc->DoQuery("SELECT tr.*, td.deny, td.alow FROM resursi AS tr LEFT JOIN dostup AS td ON td.idr=tr.id WHERE (tr.id>0 AND tr.idg=$cr) ORDER BY tr.id ASC"); # готовим запрос
				}
				if (mysqli_num_rows($this->dbc->dbr)) {
					# Заголовок группы
					echo "<a name=\"group$cr\"></a>\n";
					echo "<table class=\"tblgroup\" width=\"800\" align=\"center\">\n";
					echo "\t<tr height=\"80\">\n";
					$img = $refg[3];
					if ($img && file_exists("$this->imgdir/$img")) {
						echo "\t\t<td width=\"80\" align=\"center\">";
						echo "<img src=\"/img/$img\" width=\"64\"</td>\n";
					}
					echo "\t\t<td align=\"center\">$refg[2]&nbsp;</td>\n";
					echo "\t</tr>\n</table>\n";

					# Формируем список в группе
					echo "<table class=\"tbllst\" width=\"800\" align=\"center\">\n";
					echo "<tr height=\"80\">\n";
					echo "\t\t<th width=\"96\">Эмблема или картинка</th>\n";
					echo "\t\t<th width=\"654\">Ссылка и описание</th>\n";
					echo "\t\t<th>Управление закладкой</th>\n\t</tr>\n";

					$c = 1; #Для определения чёт/нечет

					while ($ref = $this->dbc->FetchRow()) {
						// Проверка на доступ к ресурсу (7=deny; 8=alow)
						if (count($ref) > 7) {
							if (strlen($ref[7])) {
								if (CheckAddr($this->uip, $ref[7])) {
									continue;
								}
							}
							if (strlen($ref[8])) {
								if (!CheckAddr($this->uip, $ref[8])) {
									continue;
								}
							}
						}

						// Формируем таблицу
						if ($c == 1) {
							$qa = "tr0";
							$qb = $this->c0;
						} else {
							$qa = "tr1";
							$qb = $this->c1;
						}
						$img = $ref[4];
						if ($img && file_exists("$this->imgdir/$img")) {
							$img = "/img/$img";
						// } elseif ($img) {
						//	$img = "/img/no-file64.gif";
						} else {
						//	$img = "$ref[2]/favicon.ico";
							$img = "/img/no-file64.gif";
						}
						$tw = $_SERVER{'REQUEST_SCHEME'};
						$gw = "GoW('" . $tw;
						$tw = $_SERVER{'HTTP_HOST'};
						$gw = $gw . "://" . $tw;
						$tw = "url=$ref[2]&idu=$this->uid&idg=$refg[0]&idr=$ref[0]&top=_top";
						$gw = $gw . "/cgi-bin/countr.pl?" . $tw . "', '_top')";
						echo "\t<tr class=\"$qa\" ID=\"R$idt\" ";
						echo "onmouseover='window.status=\"$ref[2]\"; NewColor(\"R$idt\", 0); return true;' ";
						echo "onmouseout='window.status=\"\"; NewColor(\"R$idt\", $c); return true;'>\n";
						echo "\t\t<td align=\"center\" height=\"96\" onclick=\"$gw; return false\">";
						echo "<img src=\"$img\" width=\"64\" title=\"$ref[5]\" align=center></td>\n";
						echo "\t\t<td onclick=\"$gw; return false\">$ref[3]&nbsp;</td>\n";
						echo "\t\t<td>&nbsp;</td>\n\t</tr>\n";
						$c = 3 - $c;
						$idt++;
					}
					echo "</table>\n<br><hr>\n";
				}
			}
		} else {
			ErrMsg("Ошибка при получении списка групп из БД.");
			$res = false;
		}



	} // MakeTable
} // class MyTbl

$tbl = new MyTbl;
if ($tbl->CheckUser() && $tbl->CheckDostup()) {
	# Формируем таблицу ссылок для разрешённого пользователя
	$tbl->MakeTable();
} else {
	# Сообщаем об отказе пользователю
	ErrMsg("Пользователь не прошёл проверку доступа");
	echo "<p>Для получения доступа обратитесь к админу</p>\n";
}
unset($tbl);
?>
	<!-- Динамическая часть страницы (Конец) -->
	</td><td width="10">&nbsp;</td>
	<td>
		<!-- Объявления и новости -->
		<table class="tbldop">
			<tr><td>
				<h1>Объявления</h1>
				<p>Сегодня 12.09.2016 года <b>День программиста</b>. Поздравим их:</p>
				<?php echo file_get_contents("pozdravim/sep-12-2016/index.inc") ?>
				<!--
				<p>Сегодня, в предверии <b>Нового Года 2017</b>, спешим поздравить Вас:</p>
				<?php echo file_get_contents("pozdravim/new-year-2017.inc") ?>
				<img src="/images/kuritca2017.jpg" width="300" align="center">
				-->
			</td></tr>
			<tr><td>
				<h1>Новости</h1>
				<!-- Динамическая часть блока новостей (Начало) -->
<?php
// Вытаскиваем новости из файлов
$ip = "127.0.0.1";
if (array_key_exists('REMOTE_ADDR', $_SERVER)) 
	if (isset($_SERVER['REMOTE_ADDR']))
		$ip = $_SERVER['REMOTE_ADDR']; # IP адрес клиента
$dr = "/news/*.txt";
$dr0 = "";
if (array_key_exists('DOCUMENT_ROOT', $_SERVER)) {
	if (isset($_SERVER['DOCUMENT_ROOT'])) {
		$dr0 = $_SERVER['DOCUMENT_ROOT']; # Путь к корню сайта (или скрипта)
	}
}
if (!$dr0)
	$dr0 = dirname(__FILE__);
$dr = $dr0 . $dr;
$arr = glob($dr);
$jc = 7; // Только 7 последних новостей
for ($i=count($arr)-1; $i>=0; $i--) {
	$fn = basename($arr[$i]);
	if (!filesize($arr[$i]))
		continue;
	$dt = substr($fn, 0, 4) . "." . substr($fn, 4, 2) . "." . substr($fn, 6, 2);
	if ($dt <= date("Y.m.d")) {
		// Прочитать содержимое файла
		$item = file($arr[$i]);
		if (!count($item))
			continue;
		$itt = $itb = "";
		$f = 0;
		$acc = true;
		foreach ($item as $lin) {
			if (strlen($lin) <= 5) {
				$f++;
				if ($f > 2)
					break;
				continue;
			}
			switch ($f)
			{
			  case 0: // Прочитали заголовок
			  	$itt .= $lin;
			  	break;
			  case 1: // Прочитали тело сообщения
			  	$itb .= $lin;
			  	break;
			  case 2: // Читаем права доступа
				//$lin = trim($lin, "\x00..\x20");
			  	if (strpos($lin, "deny ") === 0) {
					$acc = !CheckAddr($ip, substr($lin, 5));
				}
			  	if (strpos($lin, "alow ") === 0) {
					$acc = CheckAddr($ip, substr($lin, 5));
				}
			  	break;
			}
		}
		if ($acc) {
			$dt =  substr($fn, 6, 2) . "." . substr($fn, 4, 2) . "." . substr($fn, 0, 4);
			echo "<p><b>$dt</b>&nbsp;<u>$itt</u><br><i>\n<font size=\"-1\">$itb &nbsp;</font></i></p>\n";
			$jc--;
		}
	}
	if (!$jc)
		break;
}
?>
				<!-- Динамическая часть блока новостей (Конец) -->
			</td></tr>
			<tr><td>
				<h1>Календарь праздников</h1>
				<!-- Informer www.calend.ru -->
				<a href=http://www.calend.ru/ target=_blank>
					<?php
						echo "<img src=\"http://www.calend.ru/img/export/informer.png?" . date("Ymd") . "\" alt=\"Информер праздники сегодня\" title=\"Праздники сегодня\" border=\"0\">\n"; // width=\"189\" 
					?>
				</a>
				<!-- // Informer www.calend.ru -->
			</td></tr>
			<tr><td>
				<h1>Статистика</h1>
				<script type="text/javascript">GetStat("url=local&var=cycmcwcdch")</script> <!-- Были ключи "cycmcwcdchpypmpwpdph" -->
			</td></tr>
		</table>
	</td></tr>
</table>
</body>
</html>
