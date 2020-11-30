
/*
	Набор функций для конвертации предметов и их свойств
	Автор: MegaEzik
*/

;Загрузка указанных JSON файлов
IDCL_DownloadJSONList(url, file) {
	FileCopy, %file%, %file%.bak
	FileDelete, %file%
	UrlDownloadToFile, %url%, %file%
	sleep 35
	FileReadLine, line, %file%, 1	
	if (line!="{") {
		FileDelete, %file%
		sleep 35
		FileCopy, %file%.bak, %file%
	}
	FileDelete, %file%.bak
}

;Инициализация библиотеки и дополнительных компонентов
IDCL_Init() {
	IDCL_DownloadJSONList("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ru_en_stats.json", "resources\stats.json")
	FileRead, stats_list, resources\stats.json
	Globals.Set("item_stats", JSON.Load(stats_list))
	
	IDCL_DownloadJSONList("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data/ru/nameItemRuToEn.json", "resources\names.json")
	FileRead, names_list, resources\names.json
	Globals.Set("item_names", JSON.Load(names_list))
	
	IDCL_DownloadJSONList("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ruPrefSufFlask.json", "resources\presufflask.json")
	FileRead, presufflask_list, resources\presufflask.json
	Globals.Set("item_presufflask", JSON.Load(presufflask_list))
	
	/*
	IDCL_DownloadJSONList("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data/ru/sameNameItem.json", "resources\samename.json")
	FileRead, samename_list, resources\samename.json
	Globals.Set("item_samename", JSON.Load(samename_list))
	*/
}

;Получение информации c предмета
IDCL_loadInfo() {
	Clipboard:=""
	BlockInput On
	SendInput, ^c
	BlockInput Off
	sleep 35
	return Clipboard
}

;Определение уровня редкости
IDCL_lvlRarity(itemdata) {
	rlvl:=0
	rlvl:=inStr(itemdata, "Редкость: Обычный")?1:rlvl
	rlvl:=inStr(itemdata, "Редкость: Волшебный")?2:rlvl
	rlvl:=(inStr(itemdata, "Редкость: Волшебный")&&inStr(itemdata, " флакон"))?2.1:rlvl
	rlvl:=inStr(itemdata, "Редкость: Редкий")?3:rlvl
	rlvl:=inStr(itemdata, "Редкость: Уникальный")?4:rlvl
	rlvl:=inStr(itemdata, "Уникальная Реликвия")?4.1:rlvl
	rlvl:=inStr(itemdata, "Редкость: Валюта")?10:rlvl
	rlvl:=inStr(itemdata, "Редкость: Камень")?11:rlvl
	rlvl:=(inStr(itemdata, "Редкость: Камень")&&inStr(itemdata, " ваал`n"))?11.1:rlvl
	rlvl:=inStr(itemdata, "Редкость: Гадальная карта")?12:rlvl
	rlvl:=(inStr(itemdata, "Редкость: Обычный")&&inStr(itemdata, "Нажмите ПКМ, чтобы добавить это пророчество вашему персонажу."))?13:rlvl
	rlvl:=(inStr(itemdata, "Редкость: Уникальный")&&inStr(itemdata, "Объедините эту часть с четырьмя другими в Лаборатории Танэ."))?14:rlvl
	
	return %rlvl%
}

;Вывод сообщения
IDCL_splashMsg(mh, mt, t, a){
	IDCL_splashMsgDestroy()
	mtArray:=StrSplit(mt, "`n")
	widthMsg:=0
	heightMsg:=20*mtArray.MaxIndex()
	For k, val in mtArray {
		newLen:=StrLen(mtArray[k])*8
		widthMsg:=(widthMsg<newLen)?newLen:widthMsg
	}
	widthMsg:=(widthMsg<240)?240:widthMsg
	SplashTextOn, %widthMsg%, %heightMsg%, %mh%, %mt%
	if a {
		SetTimer, IDCL_splashMsgDestroy, %t%
	} else {
		sleep %t%
		IDCL_splashMsgDestroy()
	}
}

;Скрытие сообщения
IDCL_splashMsgDestroy(){
	SetTimer, IDCL_splashMsgDestroy, Delete
	SplashTextOff
}

;Внести запись в лог-файл
IDCL_writeLogFile(datatext){
	FormatTime, stime
	FileAppend, ==============================%stime%==============================`n%datatext%`n, temp\IDCL.log
}

;Очистка предмета от лишнего
IDCL_CleanerItem(itemdata){
	itemdata:=RegExReplace(itemdata, chr(0xA0), "")
	itemdata:=RegExReplace(itemdata, "`r", "")
	itemdata:=RegExReplace(itemdata, " высокого качества`n", "`n")
	itemdata:=RegExReplace(itemdata, "Вы не можете использовать этот предмет, его параметры не будут учтены`n--------`n", "")
	itemdata:=RegExReplace(itemdata, "<<.*>>", "")
	return itemdata
}

;Основная функция конвертации
IDCL_ConvertMain(itemdata){
	IDCL_writeLogFile(itemdata)
	itemdata:=IDCL_CleanerItem(itemdata)	
	;Определяем уровень редкости
	rlvl:=IDCL_lvlRarity(itemdata)	
	;Если предмет соответствует критериям, то выполняем попытку конвертировать его, иначе выдаем уведомление
	if (rlvl!=0 && rlvl!=2 && rlvl!=11.1) {
		itemdata:=IDCL_ConvertItem(itemdata, rlvl)
		IDCL_writeLogFile(itemdata)
	} else {
		IDCL_splashMsg("IDCL - Уведомление!", "Библиотека IDCL не умеет работать с данным типом предметов!", 1200, false)
	}
	return itemdata
}

;Конвертация имен
IDCL_ConvertName(name, rlvl){
	names:=Globals.Get("item_names")
	;samename:=Globals.Get("item_samename")
	new_name:=name
	/*
	if inStr(new_name, " высокого качества")
		new_name:=StrReplace(name, " высокого качества", "")
	if inStr(new_name, " исключительного качества")
		new_name:=StrReplace(name, " исключительного качества", "")
	*/
	/*
	;Пока(лига 3.10) более не актульно
	;Обработаем особые случаи с дублирующимися названиями
	If (rlvl=12 && samename.DivinationCard[new_name]) {
		return samename.DivinationCard[new_name]
	}
	Else If (rlvl=11 && samename.Gem[new_name]) {
		return samename.Gem[new_name]
	}
	Else If ((rlvl=4 || rlvl=4.1) && samename.Unique[new_name]) {
		return samename.Unique[new_name]
	}
	Else If (rlvl=13 && samename.Prophecy[new_name]) {
		return samename.Prophecy[new_name]
	}
	*/
	;Обработаем имя волшебных флаконов
	if (rlvl=2.1) {
		return IDCL_ConvertNameMFlask(new_name)
	}
	;Конвертирование Копий уникальных предметов 3.12
	if (rlvl=4 && inStr(new_name, "Копия ")) {
		replicaName:=Trim(strReplace(new_name, "Копия ", ""))
		If names[replicaName]
			return "Replica " names[replicaName]
	}
	;Конвертирование имен альтернативных камней
	if (rlvl=11 && RegExMatch(new_name, "(Пробужденный|Аномальный|Искривлённый|Фантомный):", tGem)) {
		typeGemsRuToEn:={"Пробужденный:":"Awakened","Аномальный:":"Anomalous","Искривлённый:":"Divergent","Фантомный:":"Phantasmal"}
		gemBaseRu:=Trim(strReplace(new_name, tGem, ""))
		If names[gemBaseRu]
			return typeGemsRuToEn[tGem] " " names[gemBaseRu]
	}
	;Обработаем органы метаморфов
	if (rlvl=14 && RegExMatch(new_name, "(Лёгкое|Печень|Сердце|Мозг|Глаз)", organ)) {
		metamorphRuToEn := {"Лёгкое":"Lung","Печень":"Liver","Сердце":"Heart","Мозг":"Brain","Глаз":"Eye"}
		return metamorphRuToEn[organ]
	}
	;Измененные, древние и зараженные карты
	if RegExMatch(new_name, "(Древняя|Изменённая|Заражённая)", mapre) and inStr(new_name, "Карта") {
		mapres:={"Древняя":"Elder", "Изменённая":"Shaped", "Заражённая":"Blighted"}
		new_name:=mapres[mapre] " " IDCL_ConvertName(Trim(StrReplace(new_name, mapre)), rlvl)
		return new_name		
	}
	;Обработка и конвертация синтезированных предметов
	if RegExMatch(new_name, "Синтезированн") {
		if RegExMatch(new_name, "} ") {
			sname:=StrSplit(new_name, "} ")
			new_name:="Synthesised " IDCL_ConvertName(Trim(sname[2]), rlvl)
		} else {
			new_name:=RegExReplace(new_name, "Синтезированн(ый|ая|ое|ые) ")
			new_name:="Synthesised " IDCL_ConvertName(Trim(new_name), rlvl)
		}
		new_name:=(new_name="Synthesised ")?"Synthesised Undefined Name":new_name
		return new_name
	}
	;Просто конвертируем
	new_name:=names[new_name]
	;Если имя не конвертировалось, то назначим неопределенное
	new_name:=(new_name="")?"Undefined Name":new_name
	return new_name
}

;Конвертирование имен волшебных флаконов
IDCL_ConvertNameMFlask(ItemName){
	presufflask:=Globals.Get("item_presufflask")
	
	RegExReplace(ItemName, "([А-ЯЁ])", "", matchCount)
	If (matchCount>1){
		RegExMatch(ItemName, "^[А-ЯЁ][а-яё]+", FPrefix)
		ItemName:=Trim(RegExReplace(ItemName, FPrefix))
	}
	
	SufFlaskList:=["Ордена", "адреналина", "алчности", "железной кожи", "заземления", "исцеления", "кровопускания", "оберега", "обжорства", "оживления", "осущения", "отпора", "охлаждения", "причинения", "проворства", "рефлексов", "рубцевания", "скорости", "согревания", "сопротивления", "твердолобости", "эффективности"]
	qSufFlask:=SufFlaskList.MaxIndex()
	Loop, %qSufFlask% {
		If RegExMatch(ItemName, SufFlaskList[A_Index] "$") {
			FSuffix:=SufFlaskList[A_Index]
			ItemName:=Trim(RegExReplace(ItemName, FSuffix))
		}
	}

	return Trim(presufflask[FPrefix] " " IDCL_ConvertName(ItemName, 1) " " presufflask[FSuffix])
}

;Конвертация стата
IDCL_ConvertStat(stat){
	stats:=Globals.Get("item_stats")
	;Конвертируем и проверяем, если не конвертировалось, то возвращаем оригинал
	new_stat:=stats[stat]
	new_stat:=(new_stat="")?stat:new_stat	
	;В списке соответствий статы без +, уберем его и выполним повторную попытку конвертации, после чего вернем назад
	if RegExMatch(new_stat, "[+]#") {
		new_stat:=StrReplace(new_stat, "+#", "#")
		new_stat:=IDCL_ConvertStat(new_stat)
		new_stat:=StrReplace(new_stat, "#", "+#")
	}
	return new_stat
}

;Конвертация всех статов
IDCL_ConvertAllStats(idft) {
	bidtf:=idft
	idtfen:=""
	idtferl:=""	
	;Конвертируем, что не поддается обычным правилам конвертирования модов и уберем лишнее
	idft:=StrReplace(idft, "Гнезда:", "Sockets:")
	idft:=StrReplace(idft, "Физический урон:", "Physical Damage:")
	idft:=StrReplace(idft, "Урон от стихий:", "Elemental Damage:")
	idft:=StrReplace(idft, "Размер стопки:", "Stack Size:")
	idft:=StrReplace(idft, "(макс.)", "(Max)")
	idft:=StrReplace(idft, "Опыт:", "Experience:")	
	;Разбиваем строку
	lidft:=StrSplit(idft, "`n")	
	For k, val in lidft {
		;Извлекаем часть строки не требующую перевода и препятствующую ему, при сборе вернем ее на место
		RegExMatch(lidft[k], " \(augmented\)| \(unmet\)| \(fractured\)| \(crafted\)| \(Max\)| \(implicit\)| \(enchant\)", slidft)
		lidft[k]:=StrReplace(lidft[k], slidft, "")
		;Попытка конвертировать стат
		lidft[k]:= IDCL_ConvertStat(lidft[k])
		;Если в строке найдены "от" и "до"(Разброс значений), то конвертируем так, иначе ищем нет ли "из" и пытаемся конвертировать, если снова нет, то конвертируем с одним значением
		If (RegExMatch(lidft[k], " от ") and RegExMatch(lidft[k], " до ")) {
			v:=IDCL_Value(lidft[k])
			lidft[k]:= StrReplace(lidft[k], v, "# до #")
			lidft[k]:= IDCL_ConvertStat(lidft[k])			
			v:=StrReplace(v, " до ", " to ")
			lidft[k]:=StrReplace(lidft[k], "# to #", v)
		} else if (RegExMatch(IDCL_Value(lidft[k]), " из ") && RegExMatch(lidft[k], "заряд")) {
			v:=IDCL_Value(lidft[k])
			lidft[k]:= StrReplace(lidft[k], v, "# из #")
			lidft[k]:= IDCL_ConvertStat(lidft[k])
			v:=StrReplace(v, " из ", " of ")
			lidft[k]:=StrReplace(lidft[k], "# of #", v)
		} else {
			v:=IDCL_Value(lidft[k])
			lidft[k]:= StrReplace(lidft[k], v, "#")
			lidft[k]:= IDCL_ConvertStat(lidft[k])
			lidft[k]:= StrReplace(lidft[k], "#", v)
		}
		;Флаконы
		If RegExMatch(lidft[k], "Восстанавливает (ману|здоровье): ", tflask) && InStr(lidft[k], " за ") {
			lidft[k]:=RegExReplace(lidft[k], tflask, "Recovers ")
			tflask:=inStr(tflask, "ману")?"Mana":"Life"
			lidft[k]:=RegExReplace(lidft[k], "сек.", "Seconds")
			lidft[k]:=RegExReplace(lidft[k], " за", slidft " " tflask " over")
			slidft:=""
		}
		;Кластерные смоцветы
		If RegExMatch(lidft[k], "Добавленные малые пассивные умения даруют: ") {
			pstring:=Trim(StrReplace(lidft[k], "Добавленные малые пассивные умения даруют: ", ""))
			v:=IDCL_Value(pstring)
			pstring:=StrReplace(pstring, v, "#")
			pstring:=IDCL_ConvertStat(pstring)
			pstring:=StrReplace(pstring, "#", v)
			lidft[k]:="Added Small Passive Skills grant: " pstring
		}
		;Собираем результат
		idtfen.=lidft[k] slidft "`n"
	}
	return idtfen
}

;Получаем значение из стата
IDCL_Value(ActualValueLine)
{
	Result := RegExReplace(ActualValueLine, ".*?\+?(-?\d+(?: (до|из|to) -?\d+|\.\d+)?).*", "$1")
	return Result
}

;Конвертация обычных, редких, уникальных, реликтовых предметов, гадальных карт, камней умений или валюты
IDCL_ConvertItem(itemdata, rlvl){
	;Разобьем информацию на подстроки
	sid:=StrSplit(itemdata, "`n")
	;Попытаемся сконвертировать имя предмета, а так же имя базы для редких и уникальных предметов
	sid[2]:=IDCL_ConvertName(sid[2], rlvl)	
	if (rlvl=3 || rlvl=4 || rlvl=4.1) {
		sid[3]:=IDCL_ConvertName(sid[3], rlvl)
	}
	;На гадальных картах в 6ой строке иногда написан предмет, попробуем конвертировать его
	if (rlvl=12) {
		sid[6]:=(IDCL_ConvertName(sid[6], rlvl)="Undefined Name")?sid[6]:IDCL_ConvertName(sid[6], rlvl)
	}
	;Соберем результат
	For k, val in sid {
		new_itemdata.=sid[k] "`n"
	}	
	;Конвертируем статы и проверяем конвертацию
	new_itemdata:=IDCL_ConvertAllStats(new_itemdata)
	;Проверяем результат, чистим от русскоязычных строк и выдаем уведомление
	new_itemdata:=IDCL_CheckResult(new_itemdata)
	return new_itemdata
}

;Проверка подстрок на русские символы
IDCL_CheckResult(idft){
	;Разбиваем текст на подстроки
	lidft:=StrSplit(idft, "`n")
	For k, val in lidft {
		;Если что-то не конвертировалось, то заменим на пустую строку.
		If(RegExMatch(lidft[k], "[А-Яа-яЁё]+")) {
				idtferl.=StrReplace(lidft[k], " to ", " до ") "`n"
				lidft[k]:=""
		}
		;Собираем результат
		idtfen.=lidft[k] slidft "`n"
	}
	;Уведомление о не конвертированных строках
	if(idtferl!="") {
		IDCL_splashMsg("IDCL - Не удалось конвертировать!", idtferl, 1500, false)
	}
	return idtfen
}

;Конвертирование описания с предмета из игры
IDCL_ConvertFromGame() {
	sleep 35
	itemdata:=IDCL_loadInfo()
	itemdata:=IDCL_ConvertMain(itemdata)
	Clipboard:=itemdata
	msgbox, 0x1040, Cкопировано в буфер обмена!, %itemdata%, 2
}
