#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Time::localtime;
use DBI;

# Параметры для работы с БД
my $host = "localhost"; # MySQL-сервер
my $port = "3306"; # порт, на который открываем соединение
my $user = "root"; # имя пользователя
my $pass = "mag7gi5lan\$"; # пароль
my $db = "uprfin"; # имя базы данных
my $dbh = DBI->connect("DBI:mysql:$db:$host:$port", $user, $pass);
my $sth = $dbh->do("SET NAMES utf8");

print "Content-type:text/html\n\n";

# Декодирование данных формы, переданных методом GET 
# $form_data = $ENV{'QUERY_STRING'};
# преобразование цепочек %hh в соответствующие символы 
# $form_data-=- s/%(..)/pack ("С", hex ($1))/eg; i преобразование плюсов в пробелы 
# $form_data =~ tr/+/ /;
# разбиение на пары имя=значение @pairs = split (/&/, $form_data);
# выделение из каждой пары имени и значения поля формы и сохранение
# их в ассоциативном массиве $fom_fields

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
my $name = "";
my $value = "";
my %FORM = ();

foreach my $pair (@pairs) {
	($name, $value) = split(/=/, $pair);
	$FORM{$name} = $value;
}

my $idr = $FORM{'idr'} || die "No idr";
my $idg = $FORM{'idg'} || die "No idg";
my $idu = $FORM{'idu'} || die "No idu";

# Делаем пометку о посещаемости ресурса
$sth = $dbh->prepare("INSERT INTO countr (`id`, `dt`, `idr`, `idu`, `idg`) VALUES (NULL, CURRENT_TIMESTAMP, '" . $idr . "', '" . $idu . "', '" . $idg . "')"); # готовим запрос
$sth->execute; # исполняем запрос

my $top = $FORM{'top'};
if ($top eq "") {
	$top = "_top";
}
my $url = $FORM{'url'};
print "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"0; URL=$url\" target=\"$top\">";
