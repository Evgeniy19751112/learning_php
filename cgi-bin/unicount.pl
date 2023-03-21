#!/usr/bin/perl -T

# Универсальный счётчик посещения ресурсов.
# На входе: url=имя зарегистрированого ресурса (обязательно);
#           res=тип результата: 0 (по умолчанию) - подсчёт без вывода;
#                               1 - вывод в текстовой форме (таблица с текстом);
#                               2 - вывод в текстовой форме (таблица с картинками);
#                               3 - вывод в графической форме (jpeg, вызов через img src=/unicount.pl?);
#           var=объём данных (строка признаков): cy-текущий год, py-предыдущий год;
#               cm, pm-текущий и предыдущий месяц; cw, pw-текущая и предыдущая неделя;
#               cd, pd-текущий и предыдущий день; ch, ph-текущий и предыдущий час;
#               по умолчанию - только общая статистика (добавляется всегда в конец списка);
# Для теста: ?url=local&res=0&var=pdcdphch
# База данных: db
# Таблицы: users - список пользователей (по умолчанию подсчёт для всех новых IP);
#          resurs - список зарегистрированых ресурсов (ID используем для имени Таблицы счётчика);
#          count0 - счётчик для тестов;
#          countX - счётчик для остальных ресурсов.
# Алгоритм:
#   1. Получить строку параметров и IP пользователя (с проверкой полноты);
#   2. Получить ID пользоватея (при необходимости добавить);
#   3. Получить ID ресурса (если нет, то die);
#   4. Внести данные в список счётчика;
#   5. Сделать запросы для получения данных;
#   6. Формируем результирующий код.
# Ход работы (реализация по этапам).
#   1, 2, 3, 4. 28.01.2016;
#   5, 6. 25.02.2016; Доработка запросов и реализация текстового вывода

use 5.010;
use strict;
use warnings;
use Time::localtime;
use DBI;
use GD;
use CGI ':standard';
#use CGI::Carp;

# Параметры для работы с БД
my $host = "localhost"; # MySQL-сервер
my $port = "3306"; # порт, на который открываем соединение
my $user = "yourusver"; # имя пользователя
my $pass = "BLyaD\$t81"; # пароль
my $db = "db"; # имя базы данных
my $homedir = "/home/admins/html";
our $out_ttf = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";

# Подключиться
our $dbh = DBI->connect("DBI:mysql:$db:$host:$port", $user, $pass);
our $sth = $dbh->do("SET NAMES utf8");

# IP адрес клиента
our $uip = $ENV{'REMOTE_ADDR'};
$uip = (defined ($uip)) ? $uip : "127.0.0.1";
our $uun = $ENV{'REMOTE_HOST'};
$uun = (defined ($uun)) ? $uun : $uip;
our $ucount = 0; # Признак необходимости регистрировать счётчик пользователя (1=нет)
our $uid = 0; # Пользовательский ID
&take_user;

# Получить параметры вызова
my $form_data = "";
my $method = (defined ($ENV{'REQUEST_METHOD'}) ? $ENV{'REQUEST_METHOD'} : "");
if ($method eq "GET") {
	$form_data = $ENV{'QUERY_STRING'}; 
} else {
	read (STDIN, $form_data, (defined ($ENV{'CONTENT_LENGTH'}) ? $ENV{'CONTENT_LENGTH'} : 0));
}
$form_data =~ s/%(..)/pack ("C", hex ($1))/eg; 
$form_data =~ tr/+/ /; 
my @pairs = split (/&/, $form_data);
our %FORM = ();
foreach my $pair (@pairs) {
	my ($name, $value) = split(/=/, $pair);
	$FORM{$name} = $value;
}

# Инициализация параметров
our $url = $FORM{'url'}; # || die "Ошибка: не указан параметр url\n";
$url = (defined ($url)) ? $url : "local";
our $res = $FORM{'res'};
$res = (defined ($res)) ? $res : "3";
our $var = $FORM{'var'};
$var = (defined ($var)) ? $var : "";
our $urv = 0;

# Определить, что это за ресурс
my $c = 0;
eval {
	$sth = $dbh->prepare("SELECT id FROM resurs WHERE `name`=\"$url\"");
	$c = $sth->execute;
	$c = (defined ($c) ? $c : 0);
};
if ($@ || (! $c)) {
	&close_db;
	die "Ошибка определения ресурса $res\n";
}
if (my $ref = $sth->fetchrow_arrayref) {
	$urv = $$ref[0];
}


# Делаем пометку о посещаемости ресурса
if (! $ucount) {
	eval {
		$sth = $dbh->prepare("INSERT INTO count$urv (id, dt, idu) VALUES (NULL, CURRENT_TIMESTAMP, '" . $uid . "')"); # готовим запрос
		$sth->execute; # исполняем запрос
	};
	if ($@) {
		&close_db;
		die "Ошибка записи посещения ресурса $res\n";
	}
}

# Делаем запросы для получения статистики
our $st_total = 0;
our $st_cy = 0;
our $st_py = 0;
our $st_cm = 0;
our $st_pm = 0;
our $st_cw = 0;
our $st_pw = 0;
our $st_cd = 0;
our $st_pd = 0;
our $st_ch = 0;
our $st_ph = 0;
my $qs = "";
eval {
	# Всего
	$sth = $dbh->prepare("SELECT COUNT(*) FROM count$urv");
	$c = $sth->execute; # исполняем запрос
	$c = (defined ($c) ? $c : 0);
	if ($c && (my $ref = $sth->fetchrow_arrayref)) {
		$st_total = $$ref[0];
	}

	# cy-текущий год
	if (index($var, "cy") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE YEAR(NOW()) = YEAR(dt)";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_cy = $$ref[0];
		}
	}

	# py-предыдущий год
	if (index($var, "py") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE YEAR(NOW()) - 1 = YEAR(dt)";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_py = $$ref[0];
		}
	}

	# cm-текущий месяц
	if (index($var, "cm") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE (MONTH(NOW()) = MONTH(dt)) ";
		$qs = $qs . "AND (YEAR(NOW()) = YEAR(dt))";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_cm = $$ref[0];
		}
	}

	# pm-предыдущий месяц
	if (index($var, "pm") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE ((MONTH(NOW() - INTERVAL ";
		$qs = $qs . "1 MONTH) = MONTH(dt)) AND (YEAR(NOW()) = YEAR(dt))) OR (";
		$qs = $qs . "(MONTH(NOW()) = 1) AND (YEAR(NOW()) - 1 = YEAR(dt)))";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_pm = $$ref[0];
		}
	}

	# cw-текущая неделя
	if (index($var, "cw") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE UNIX_TIMESTAMP(dt) >= ";
		$qs = $qs . "UNIX_TIMESTAMP(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL ";
		$qs = $qs . "WEEKDAY(CURDATE()) DAY), INTERVAL 0 SECOND)) AND UNIX_TIMESTAMP(dt) ";
		$qs = $qs . "<= UNIX_TIMESTAMP(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL ";
		$qs = $qs . "WEEKDAY(CURDATE()) DAY), INTERVAL \"6 0:0:0\" DAY_SECOND))";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_cw = $$ref[0];
		}
	}

	# pw-предыдущая неделя
	if (index($var, "pw") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE UNIX_TIMESTAMP(dt) >= ";
		$qs = $qs . "UNIX_TIMESTAMP(DATE_ADD(DATE_SUB(CURDATE(), INTERVAL ";
		$qs = $qs . "(WEEKDAY(CURDATE()) + 7) DAY), INTERVAL 0 SECOND)) AND ";
		$qs = $qs . "UNIX_TIMESTAMP(dt) <= UNIX_TIMESTAMP(DATE_ADD(DATE_SUB";
		$qs = $qs . "(CURDATE(), INTERVAL (WEEKDAY(CURDATE()) + 7) DAY), ";
		$qs = $qs . "INTERVAL \"6 0:0:0\" DAY_SECOND))";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_pw = $$ref[0];
		}
	}

	# cd-текущий день
	if (index($var, "cd") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE TO_DAYS(NOW()) = TO_DAYS(dt)";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_cd = $$ref[0];
		}
	}

	# pd-предыдущий день
	if (index($var, "pd") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE TO_DAYS(NOW()) - 1 = TO_DAYS(dt)";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_pd = $$ref[0];
		}
	}

	# ch-текущий час
	if (index($var, "ch") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE (UNIX_TIMESTAMP(NOW() - ";
		$qs = $qs . "INTERVAL 1 HOUR) < UNIX_TIMESTAMP(dt)) AND (UNIX_TIMESTAMP";
		$qs = $qs . "(NOW()) >= UNIX_TIMESTAMP(dt))";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_ch = $$ref[0];
		}
	}

	# ph-предыдущий час
	if (index($var, "ph") >= 0) {
		$qs = "SELECT COUNT(*) FROM count$urv WHERE (UNIX_TIMESTAMP(NOW() - ";
		$qs = $qs . "INTERVAL 2 HOUR) < UNIX_TIMESTAMP(dt)) AND (UNIX_TIMESTAMP";
		$qs = $qs . "(NOW() - INTERVAL 1 HOUR) >= UNIX_TIMESTAMP(dt))";
		$sth = $dbh->prepare($qs);
		$c = $sth->execute; # исполняем запрос
		$c = (defined ($c) ? $c : 0);
		if ($c && (my $ref = $sth->fetchrow_arrayref)) {
			$st_ph = $$ref[0];
		}
	}
};
if ($@) {
	&close_db;
	die "Ошибка выполнения запроса \"$qs\" для ресурса \"$res\"\n";
}

# Формируем вывод результата
if ($res == 3) {
	print "Content-type: image/jpeg\n\n";
} else {
	print "Content-type: text/html\n\n";
}
if ($res == 0) {
	# Результат не выводим. Но сформруем коментарий для отладки
	print "<!-- Всего: $st_total -->\n";
	if (index($var, "py") >= 0) {
		print "<!-- в прошлом году: $st_py -->\n";
	}
	if (index($var, "cy") >= 0) {
		print "<!-- в этом году: $st_cy -->\n";
	}
	if (index($var, "pm") >= 0) {
		print "<!-- в прошлом месяце: $st_pm -->\n";
	}
	if (index($var, "cm") >= 0) {
		print "<!-- в этом месяце: $st_cm -->\n";
	}
	if (index($var, "pw") >= 0) {
		print "<!-- на прошлой неделе: $st_pw -->\n";
	}
	if (index($var, "cw") >= 0) {
		print "<!-- на этой неделе: $st_cw -->\n";
	}
	if (index($var, "pd") >= 0) {
		print "<!-- вчера: $st_pd -->\n";
	}
	if (index($var, "cd") >= 0) {
		print "<!-- сегодня: $st_cd -->\n";
	}
	if (index($var, "ph") >= 0) {
		print "<!-- за прошлый час: $st_ph -->\n";
	}
	if (index($var, "ch") >= 0) {
		print "<!-- за этот час: $st_ch -->\n";
	}
} elsif ($res == 1) {
	print "<style>\n.radius {\n background: #f0f0f0; /* Цвет фона */\n ";
	print "border: 1px solid black; /* Параметры рамки */\n ";
	print "padding: 15px; /* Поля вокруг текста */\n margin-bottom: 10px; ";
	print "/* Отступ снизу */\nwidth: 128px;\nheight: 32;\n}\n</style>\n";
	print "<div style=\"border-radius: 12px;\" class=\"radius\" title=\"Счётчик посещаемости\">\n";
	print "Всего: $st_total\n";
	print "</div>\n";
} elsif ($res == 2) {
} elsif ($res == 3) {
	# Формируем графического изображения счётчика
	$qs = 20 + length ($var) * 7;

	# создаем изображение
	my $im = new GD::Image(164, $qs);
	my ($qa, $qb) = $im->getBounds();
	$qa--;
	$qb--;

	# Определяем цвета
	my $white = $im->colorAllocate(255, 255, 255);
	my $black = $im->colorAllocate(  0,   0,   0);
	my $red   = $im->colorAllocate(255,   0,   0);
	my $blue  = $im->colorAllocate(  0,   0, 255);
	my $fon   = $im->colorAllocate(153, 204, 102);

	# Делаем бэкграунд прозрачным и interlaced
	$im->transparent($white);
	$im->interlaced('true');

	# Рисуем число
	$im->rectangle(0, 0, $qa, $qb, $black); # Рисуем черную рамку
	$im->filledArc(0, 0, 15, 15, 0, 360, $white, gdArc); # Рисуем сектор
	$im->filledArc(0, $qb, 15, 15, 0, 360, $white, gdArc); # Рисуем сектор
	$im->filledArc($qa, 0, 15, 15, 0, 360, $white, gdArc); # Рисуем сектор
	$im->filledArc($qa, $qb, 15, 15, 0, 360, $white, gdArc); # Рисуем сектор
	$im->arc(0, 0, 15, 15, 0, 360, $black); # Рисуем сектор
	$im->arc(0, $qb, 15, 15, 0, 360, $black); # Рисуем сектор
	$im->arc($qa, 0, 15, 15, 0, 360, $black); # Рисуем сектор
	$im->arc($qa, $qb, 15, 15, 0, 360, $black); # Рисуем сектор
	$im->fill($qa / 2, $qb / 2, $fon);
	$qs = 14;
	$im->stringFT($blue, $out_ttf, 8, 0, 14, $qs, "Визитов всего: $st_total");
	if (index($var, "py") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> в прошлом году: $st_py");
	}
	if (index($var, "cy") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> в этом году: $st_cy");
	}
	if (index($var, "pm") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> в прошлом месяце: $st_pm");
	}
	if (index($var, "cm") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> в этом месяце: $st_cm");
	}
	if (index($var, "pw") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> на прошлой неделе: $st_pw");
	}
	if (index($var, "cw") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> на этой неделе: $st_cw");
	}
	if (index($var, "pd") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> вчера: $st_pd");
	}
	if (index($var, "cd") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> сегодня: $st_cd");
	}
	if (index($var, "ph") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> за прошлый час: $st_ph");
	}
	if (index($var, "ch") >= 0) {
		$qs += 14;
		$im->stringFT($blue, $out_ttf, 8, 0, 8, $qs, "> за этот час: $st_ch");
	}

	# включаем двоичный режим вывода
	binmode STDOUT;
	select(STDOUT);
	undef $/;
	print $im->jpeg(100);
	#close STDOUT;
} else {
	# Такой вариант не реализован. Сообщаем лаконично
}
#------------------------------------------------------------------------------------------
# Примеры со скруглёнными углами
	#print "<style>\n.radius {\n background: #f0f0f0; /* Цвет фона */\n ";
	#print "border: 1px solid black; /* Параметры рамки */\n ";
	#print "padding: 15px; /* Поля вокруг текста */\n margin-bottom: 10px; ";
	#print "/* Отступ снизу */\nwidth: 128px;\nheight: 32;\n}\n</style>\n";
	#print "<div style=\"border-radius: 12px;\" class=\"radius\" width=\"128\" height=\"16\">\n";
	#print "border-radius: 8px;\nВсего: $st_total\n";
	#print "</div>\n";
	#print "<div style=\"border-radius: 50px 0 0 50px;\" class=\"radius\">\n";
	#print "border-radius: 50px 0 0 50px;\n";
	#print "</div>\n";
	#print "<div style=\"border-radius: 40px 10px\" class=\"radius\">\n";
	#print "border-radius: 40px 10px;\n";
	#print "</div>\n";
	#print "<div style=\"border-radius: 10em/1em;\" class=\"radius\">\n";
	#print "border-radius: 13em/3em;\n";
	#print "</div>\n";
	#print "<div style=\"border-radius: 13em 0.5em/1em 0.5em;\" class=\"radius\">\n";
	#print "border-radius: 13em 0.5em/1em 0.5em;\n";
	#print "</div>\n";
#------------------------------------------------------------------------------------------
# Формирование картинки
#   if($iformat eq "jpg"    $iformat eq "png") {
#        &print_counter($iformat, $counter_value);
#    }
#    else {
#        &print_error_image("Графический формат $iformat не поддерживается");
#    }
#}
#sub print_counter {
#    my($iformat, $counter_value) = @_;
#    my($COUNTER_SIZE) = 4;
#    my($im) = GD::Image->new("${iformat}s/0.${iformat}");
#    if(!defined($im)) {
#        &print_error_image("\$im не может быть инициализировано");
#        exit;
#    }
#    my($w, $h) = $im->getBounds();
#    undef $im;
#    my($printim) = GD::Image->new($w * $COUNTER_SIZE, $h);
#    $printim->colorAllocate(255, 255, 255);
#    my($pos, $l, $temp, $digit, $x, $srcim);
#    $x = 0;
#    for($pos = $COUNTER_SIZE - 1; $pos >= 0; $pos--) {
#        if($pos > length($counter_value) - 1) {
#            $digit = 0;
#        }
#        else {
#            $l = length($counter_value);
#            $temp = $l - $pos - 1;
#            $digit = substr($counter_value, $temp, 1);
#        }
#        $srcim = GD::Image->new("${iformat}s/${digit}.${iformat}");
#        $printim->copy($srcim, $x, 0, 0, 0, $w, $h);
#        $x += $w;
#        undef $srcim;
#    }
#    if($iformat eq "jpg") {
#        print "Content-type: image/jpeg\n\n";
#        print $printim->jpeg(100);
#    }
#    else {
#        print "Content-type: image/png\n\n";
#        print $printim->png;
#    }
#}
#------------------------------------------------------------------------------------------

# Закончили работать
&close_db;

#------------------------------------------------------------------------------------------
# Подпрограммы
sub close_db {
	my $rc;
	$rc = ($sth->finish) if (defined $sth);    # закрываем
	#$rc = ($stg->finish) if (defined $stg);    # закрываем
	#$rc = ($stb->finish) if (defined $stb);    # закрываем
	$rc = $dbh->disconnect;  # соединение
}

#------------------------------------------------------------------------------------------

sub take_user {
	# Определяем пользователя (новый/старый)
	my @mas = split (/\./, $uip);
	my $qb = "SELECT id,un,needcount as nc FROM users WHERE";
	my $qa = "";
	my $c = 0;

	# Формируем запрос к БД
	for ($c=0; $c<=3; $c++) {
		$qb = $qb . (($c) ? " AND " : " (id>0 AND ") . "g$c='" . $mas[$c] . "'";
	}
	$qb = $qb . ")";

	# Получаем данные
	eval {
		$sth = $dbh->prepare($qb); # готовим запрос
		$c = $sth->execute; # исполняем запрос
	};
	if ($@) {
		&close_db;
		die "Ошибка при получении данных пользователя $uip из БД\n";
	}

	$c = (defined ($c) ? $c : 0);
	if ($c == 0) {
		# Добавить пользователя в БД (раз его нет)
		$qa = "(NULL, CURRENT_TIMESTAMP,";
		for ($c=0; $c<=3; $c++) {
			$qa = "$qa '" . $mas[$c] . "',";
		}
		eval {
			$sth = $dbh->prepare("INSERT INTO users (id, dt, g0, g1, g2, g3, un, needcount) VALUES $qa '" . $uun . "', 0)"); # готовим запрос
			$sth->execute; # исполняем запрос
		};
		if ($@) {
			&close_db;
			die "Ошибка добавления нового пользователя $uun в БД\n";
		}
		eval {
			$sth = $dbh->prepare($qb); # готовим запрос
			$c = $sth->execute; # исполняем запрос
		};
		if ($@) {
			&close_db;
			die "Ошибка при контрольном получении данных пользователя $uip из БД\n";
		}
		$c = (defined ($c) ? $c : 0);
	}
	if ($c == 0) {
		print "<h0 color='red'>Ошибка определения персональных данных клиента $uip</h0>\n";
		die "Ошибка определения персональных данных клиента $uip.\n";
	}
	if (my $ref = $sth->fetchrow_arrayref) {
		$uid = $$ref[0];
		$uun = $$ref[1];
		if ($uun eq "") {
			$uun = $uip;
		}
		$ucount = $$ref[2];
		if ($ucount eq "") {
			$ucount = "0";
		}
	}
}