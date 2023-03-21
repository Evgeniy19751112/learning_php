#!/usr/bin/perl

#############################################################################
# Случайные анекдоты ver 1.0                                           	    #
# Написан Евгенийем Тявкиным 21 февраля 2005 года                           #
# Вы можете направлять свои пожелания и вопросы на user00@klass.net         #
# или через www.etv.hotmail.ru                                              #
#############################################################################

##################################################
# Определение переменных:
##################################################

$path_file = "humor.dtb";

$delimiter = "\@\@\@";
open(FILE, "$path_file");
@FILE = <FILE>;
close(FILE);
$phrases = join('<br>',@FILE);
@phrases = split(/$delimiter/,$phrases);
srand(time ^ $$);
$phrase = rand(@phrases);
my $out = $phrases[$phrase];
print "Content-type:text/html\n\n";
print "<p align=center><table border=\"0\" cellpadding=\"3\"  ";
print "cellspacing=\"0\" width=\"500\">\n";
print "<tr>\n";
print "<td bgcolor=\"#BF95FF\" width=\"90%\">Случайный анекдот</td>\n";
print "</tr>\n";
print "<tr>\n";
print "<td bgcolor=white>$out</td>\n";
print "</tr>\n";
print "</table></p>\n";