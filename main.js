// Открыть ссылку в окне указанном в name
function GoW(url, name) {
	GoW = window.open(url, name, 'width=100%, height=100%');
}

// Изменить фон элемента при наведении указателя
// idCell - ID элемента, col - номер цвета
function NewColor(idCell, col) {
	var ci = (col == 0) ? "#7777FF" : (col == 1) ? "#BEE6FF" : "#DCF2FF";
	eval('document.all.' + idCell + '.style.background = "' + ci + '"');
	eval('document.getElementById("' + idCell + '").style.background = "' + ci + '"');
	if (col == 0) {
		eval('document.all.' + idCell + '.style.cursor="hand"');
		eval('document.getElementById("' + idCell + '").style.cursor="hand"');
	}
}

// random words and digits
function randWD(n) {  
	var s ='';
	while (s.length < n) s += Math.random().toString(36).slice(2, 12);
	return s.substr(0, n);
} //result is such as "46c17fkfpl"

// random words and digits by the wocabulary
function randWDclassic(n) {  
	var s ='', abd ='abcdefghijklmnopqrstuvwxyz0123456789', aL = abd.length;
	while(s.length < n) s += abd[Math.random() * aL|0];
	return s;
} //such as "46c17fkfpl"

// Добавить статистику посещения страницы
function GetStat(par) {
	var w = window.location.href;
	var p = w.substr(0, 5);
	if (p == "http:") {
		w = w.substr(7, 21);
	} else {
		w = "192.168.3.203";
	}
	var i = w.indexOf("/");
	if (i > 0) {
		w = w.substr(0, i);
	}
	document.write("<img src='http://" + w + "/cgi-bin/unicount.pl?res=3&" + par + "&nop=" + randWD(15) + "'>");
}
