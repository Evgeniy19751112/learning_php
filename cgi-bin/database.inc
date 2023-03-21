use DBI;

# Параметры для работы с БД
my $host = "localhost"; # MySQL-сервер
my $port = "3306"; # порт, на который открываем соединение
my $user = "root"; # имя пользователя
my $pass = "mag7gi5lan\$"; # пароль
my $db = "uprfin"; # имя базы данных
my $dbh = DBI->connect("DBI:mysql:$db:$host:$port", $user, $pass);
my $sth = $dbh->do("SET NAMES utf8");
