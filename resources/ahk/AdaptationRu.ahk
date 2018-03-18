/*

Вспомогательные функции для русской адаптации


*/



; конвертируем русские названия модов в их английские варианты
; сохраняем русские названия модов в отдельном параметре
ConvertRuModToEn(_item)
{
	For k, imod in _item.mods {
		
		_item.mods[k].name_ru := _item.mods[k].name
		_item.mods[k].name := Ru_En_Stats_Value(_item.mods[k].name)
		
		; попытаемся сконвертировать оригинальное название мода, 
		; это нужно для модов с числами, например "Имеет 1 гнездо" 
		; - для таких модов в файле должно быть соответствие полному названию с числовыми значениями
		_item.mods[k].name_orig_en := Ru_En_Stats_Value(_item.mods[k].name_orig)
		
		; если мод не был сконвертирован
		If (_item.mods[k].name = _item.mods[k].name_ru) {		
			; в массиве соответствий названия модов без плюса в начале, поэтому если он присутствует, то избавляемся от него
			RegExMatch(_item.mods[k].name, "(.*)([+]#)(.*)", mod_name)			
			modRu := mod_name1 "#" mod_name3
			modEn := Ru_En_Stats_Value(modRu)
			; и добавляем после получения английского названия
			_item.mods[k].name := StrReplace(modEn, "#", "+#")
		}
	}
;console_log(_item, "_item")
	Return _item
}


; конвертирование для одной строки мода
ConvertRuOneModToEn(smod)
{
	; в массиве соответствий названия модов без плюсов в начале, поэтому если он присутствует, то избавляемся от него		
	If (RegExMatch(smod, "^([+])")) {
		RegExMatch(smod, "^([+])(.*)", mod_name)
		; и добавляем после получения английского названия
		smod := "+" . Ru_En_Stats_Value(mod_name2)
	}
	Else {
		smod := Ru_En_Stats_Value(smod)
	}

	Return smod
}

;
Ru_En_Stats_Value(smod)
{
	ru_en_stats := Globals.Get("ru_en_stats")

	smod_en := ru_en_stats[smod]
	
	If(not smod_en) {
	
		; для случая с константой - имя мода содержит # вместо константы
		res := nameModNumToConst(smod)
		If (res.IsNameRuConst) {
			smod_en := ru_en_stats[res.nameModConst]
		}
		
		If(not smod_en) {	
			return smod
		}
	}
	
	; избавимся от символа новой строки заменив его на пробел
	; - для случая, когда в файле соответствий в английском названии мода присутствует символ новой строки, т.к. в модах poetrade он отсутствует
	StringReplace, smod_en, smod_en, `n, %A_Space%, All
	
	return smod_en
}

; конвертирует имя мода с # в имя мода с константами
nameModNumToConst(nameMod)
{
	nameModNum  := Globals.Get("nameModNum")
	nameModConst := nameModNum[nameMod]
	
	result := {}
	
	If(not nameModConst)
	{
		result.IsNameRuConst := false
		result.nameModConst := nameMod
		return result
	} 
	
	result.IsNameRuConst := true
	result.nameModConst := nameModConst
;console_log(nameMod, "nameMod")	
	return result
}

;конвертирует русские имена предметов в английский вариант
ConvertRuItemNameToEn(itemRu, currency=false)
{
	Global Item
	
	; совпадает с названием валюты - исключить
	If (not currency and RegExMatch(itemRu, "i)Древняя сфера")) {
		return itemRu
	}
	
	;itemRu_ := Trim(RegExReplace(itemRu, "i)высокого качества", ""))
	itemRu_ := Trim(StrReplace(itemRu, "высокого качества", ""))
	
	If (Item.IsMap) {
		; для карты "Вихрь хаоса" имя  будем формировать вручную, т.к. в английском
		; названии карты присутствует символ отсутвующий в ANSI кодировке - "o" с двумя точками вверху
		; соответственно данный символ не сохраняется в файле с ANSI кодировкой
		;If (RegExMatch(itemRu_, "Вихрь хаоса")) 
		IfInString, itemRu_, Вихрь хаоса
		{
			itemEn := "Maelstr" chr(0xF6) "m of Chaos"
			return itemEn
		}
	}
	
	; обработаем особые случаи предметов с одинаковыми названиями
	sameNameItem  := Globals.Get("sameNameItem")
	itemEn := ""
	If (Item.IsDivinationCard) {
		itemEn := sameNameItem.DivinationCard[itemRu_]
		If (itemEn) {
			return itemEn
		}
	}
	Else If (Item.IsGem) {
		itemEn := sameNameItem.Gem[itemRu_]
		If (itemEn) {
			return itemEn
		}
	}

	; массив соответствий базовых имен предметов на русском языке их английским вариантам
	nameItemRuToEn := Globals.Get("nameItemRuToEn")	
	
	itemEn := ""
	itemEn := nameItemRuToEn[itemRu_]
	
	If (not itemEn) {
		; если соответствия не найдено, возвращаем имя на русском
		; возможно необходимо как-то обрабатывать такой случай - нельзя, в другом коде используется проверка на русские символы
		itemEn := itemRu
	}	
	
	return itemEn
}

; конвертирование полного имени волшебных флаконов в английский вариант
ConvertRuFlaskNameToEn(nameRu, baseNameRu)
{
	ruPrefSufFlask := TradeGlobals.Get("ruPrefSufFlask")
	
	affName := RegExReplace(nameRu, baseNameRu, "")
	
	; извлекаем аффиксы из названий	
	If (RegExMatch(affName, "^([а-яА-ЯёЁ]+) ([а-яА-ЯёЁ ]+)*$", aff_name))
	{		
		pref := Trim(aff_name1)
		suff := Trim(aff_name2)
	} ; только префикс
	Else If (RegExMatch(affName, "([А-ЯЁ][а-яё]+)", aff_name)){
		pref := Trim(aff_name1)
		suff := ""
	} ; только суффикс
	Else If (RegExMatch(affName, "([а-яё]+)", aff_name)){
		pref := ""
		suff := Trim(aff_name1)
	}
	
	
	;MsgBox full_ru:%nameRu% aff_ru:%affName% `npref: %pref% suff: %suff% 
	nameEn := ""
	nameEn := ruPrefSufFlask[pref] " " ConvertRuItemNameToEn(baseNameRu) " " ruPrefSufFlask[suff]
	;MsgBox %nameRu% `n%nameEn% 
	
	return nameEn
}


; есть моды с константами идущими первыми в имени мода
; в результате извлечение значения мода работает не корректно
; такие моды необходимо обработать подготовив их к извлечению значения
ConverNameModToValue(nameMod, name_ru)
{
	; извлекаем значение константы
	RegExMatch(name_ru, ".*(\d+).*", constValue)
	; извлекаем положение константы в строке
	RegExMatch(name_ru, "P).*(\d+).*", const)
	
	If (const and constValue) {
		; удаляем из оригинального мода константу
		nameMod := RegExReplace(nameMod, constValue1, "#",,1, constPos1)
		;console_log(name_ru, "name_ru")	
		;console_log(nameMod, "nameMod")	
	}

	return nameMod
}


; инициализация английских названий предметов
InitNameEnItem()
{
	Global Item
	
	; конвертирование полного имени волшебных флаконов
	If (Item.IsFlask and Item.RarityLevel = 2) {
		Item.Name_En := ConvertRuFlaskNameToEn(Item.Name, Item.BaseName)
	}
	Else {
		; сконвертируем по возможности русские названия в английские
		Item.Name_En := ConvertRuItemNameToEn(Item.Name, Item.IsCurrency)
	}
	
	Item.BaseName_En := ConvertRuItemNameToEn(Item.BaseName, Item.IsCurrency)
}

; функция инициализации массива соответствий для названий валюты с poe.trade
InitRuPrefSufFlask()
{
	FileRead, ruPrefSufFlask, %A_ScriptDir%\data_trade\ru\ruPrefSufFlask.json	
	TradeGlobals.Set("ruPrefSufFlask", JSON.Load(ruPrefSufFlask))
}

; функция инициализации массива соответствий перфиксов и суффиксов в названиях волшебных флаконов русских вариантов английским
InitBuyoutCurrencyEnToRu()
{
	buyoutCurrencyEnToRu := {}
	buyoutCurrencyEnToRu["blessed"]    := "благодатных сфер"
	buyoutCurrencyEnToRu["chisel"]     := "резцов"
	buyoutCurrencyEnToRu["chaos"]      := "хаосов"
	buyoutCurrencyEnToRu["chromatic"]  := "цветных сфер"
	buyoutCurrencyEnToRu["alchemy"]    := "сфер алхимии"
	buyoutCurrencyEnToRu["divine"]     := "божественных сфер"
	buyoutCurrencyEnToRu["exalted"]    := "возвышений"
	buyoutCurrencyEnToRu["gcp"]        := "призм камнереза"
	buyoutCurrencyEnToRu["jewellers"]  := "сфер златокузнеца"
	buyoutCurrencyEnToRu["alteration"] := "сфер перемен"
	buyoutCurrencyEnToRu["chance"]     := "сфер удачи"
	buyoutCurrencyEnToRu["fusing"]     := "сфер соединений"
	buyoutCurrencyEnToRu["regret"]     := "сфер раскаяния"
	buyoutCurrencyEnToRu["scouring"]   := "сфер очищения"
	buyoutCurrencyEnToRu["regal"]      := "сфер царей"
	buyoutCurrencyEnToRu["vaal"]       := "сфер ваал"
	buyoutCurrencyEnToRu["coin"]       := "монет Просперусов"
	buyoutCurrencyEnToRu["silver"]     := "серебряных монет"

	TradeGlobals.Set("buyoutCurrencyEnToRu", buyoutCurrencyEnToRu)
}

; конвертирует название валюты с английского на русский
ConvertBuyoutCurrencyEnToRu(buycurEn)
{
	buyoutCurrencyEnToRu := TradeGlobals.Get("buyoutCurrencyEnToRu")
	buycurRu := buyoutCurrencyEnToRu[ buycurEn ]

/*
console.log("############Value: buyoutCurrencyEnToRu ############")
tmp := buyoutCurrencyEnToRu
console.log(tmp)
console.log("##############################")
*/	
	If (buycurRu){
		return buycurRu
	}
	Else {
		return buycurEn
	}
}

; функция вывода значения переменной в отладачную консоль
; var_ - переменная
; name_var - текстовое имя переменной, либо текст который будут выведен в заголовок блока сообщения
; console_log(var_, "var_")
console_log(var_, name_var)
{
	console.log("############Value: " name_var " ############")
	console.log(var_)
	console.log("##############################")
}

; тестовая функция для отладки
testAdp(name_tst)
{
	dataTst := TradeGlobals.Get("VariableUniqueData")
	
	For index, uitem in dataTst {
		If (uitem.name = "Axiom Perpetuum") {
			console.log("############Value: uitem.mods.Length()_TST " name_tst " ############")
			tmp := uitem.mods.Length()
			console.log(tmp)
			console.log("##############################")
		}
		
	}
}