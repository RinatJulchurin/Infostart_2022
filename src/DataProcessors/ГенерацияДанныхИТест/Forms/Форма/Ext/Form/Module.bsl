
&НаСервереБезКонтекста
Процедура ГенерацияДанныхНаСервере(Дата)
	ДатаТеста = НачалоМесяца(Дата);
	Для Сч = 1 По 10000 Цикл
		ДокОб = Документы.Документ1.СоздатьДокумент();
		ДокОб.Дата = ДатаТеста + Сч * 3;
		ДокОб.Записать(РежимЗаписиДокумента.Проведение);
	КонецЦикла;
КонецПроцедуры

&НаКлиенте
Процедура ГенерацияДанных(Команда)
	ГенерацияДанныхНаСервере(Объект.Дата);
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ТестНаСервере(Дата)
	ДатаТеста = НачалоМесяца(Дата);
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ЗапросОстатковНаСервере(Дата)
	ДатаТеста = НачалоМесяца(Дата);
	Запрос = Новый Запрос("ВЫБРАТЬ
	                      |	Влож.Измерение1 КАК Измерение1,
	                      |	СУММА(Влож.Ресурс1Остаток) КАК Ресурс1Остаток,
	                      |	СУММА(Влож.Ресурс1Остаток2) КАК Ресурс1Остаток2
	                      |ИЗ
	                      |	(ВЫБРАТЬ
	                      |		РегистрНакопления1Остатки.Измерение1 КАК Измерение1,
	                      |		РегистрНакопления1Остатки.Ресурс1Остаток КАК Ресурс1Остаток,
	                      |		0 КАК Ресурс1Остаток2
	                      |	ИЗ
	                      |		РегистрНакопления.РегистрНакопления1.Остатки(&Дата, ) КАК РегистрНакопления1Остатки
	                      |	
	                      |	ОБЪЕДИНИТЬ ВСЕ
	                      |	
	                      |	ВЫБРАТЬ
	                      |		РегистрНакопления1Остатки.Измерение1,
	                      |		0,
	                      |		РегистрНакопления1Остатки.Ресурс1Остаток
	                      |	ИЗ
	                      |		РегистрНакопления.РегистрНакопления1.Остатки(&Дата2, ) КАК РегистрНакопления1Остатки) КАК Влож
	                      |
	                      |СГРУППИРОВАТЬ ПО
	                      |	Влож.Измерение1"); 
	Запрос.УстановитьПараметр("Дата", КонецМесяца(ДатаТеста));
	Запрос.УстановитьПараметр("Дата2", ДобавитьМесяц(ДатаТеста, 2));  
	Выб = Запрос.Выполнить().Выбрать();
	Если Выб.Следующий() Тогда
		Сообщить("На " + сокрлп(Запрос.Параметры.Дата) + " остаток " + сокрлп(Выб.Ресурс1Остаток));
		Сообщить("На " + сокрлп(Запрос.Параметры.Дата2) + " остаток " + сокрлп(Выб.Ресурс1Остаток2));
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ЗапросОстатков(Команда)
	ЗапросОстатковНаСервере(Объект.Дата);
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ТестИсправленныйНаСервере(Дата)
	ДатаТеста = НачалоМесяца(Дата);                  
	НачСуммаДельта = -1000;
	Шаг = 10;                  
	КонСуммаДельта = 0;
	Запрос = Новый Запрос("ВЫБРАТЬ ПЕРВЫЕ 1
	                      |	РегистрНакопления1.Регистратор КАК Регистратор
	                      |ИЗ
	                      |	РегистрНакопления.РегистрНакопления1 КАК РегистрНакопления1
	                      |ГДЕ
	                      |	РегистрНакопления1.Период < &Дата
	                      |
	                      |УПОРЯДОЧИТЬ ПО
	                      |	РегистрНакопления1.Период УБЫВ");
	Запрос.УстановитьПараметр("Дата", ДобавитьМесяц(ДатаТеста, 1));
	Выборка = Запрос.Выполнить().Выбрать();                          
	
	Набор = РегистрыНакопления.РегистрНакопления1.СоздатьНаборЗаписей();
	Набор.Отбор.Регистратор.Использование = Истина; //вроде и так Истина  
	
	ПереставитьГраницуВФоне.ПереставитьГраницуВФонеСБлокировкой(ДобавитьМесяц(КонецМесяца(ДатаТеста), -1));
	
	Парам = Новый Массив;    
	Парам.Добавить(КонецМесяца(ДатаТеста));
	ФоновыеЗадания.Выполнить("ПереставитьГраницуВФоне.ПереставитьГраницуВФонеСБлокировкой", Парам);
		
	Если Выборка.Следующий() Тогда
		Набор.Отбор.Регистратор.Значение = Выборка.Регистратор;
		Набор.Прочитать();     
		Набор.ОбменДанными.Загрузка = Истина;
		Набор.ОбменДанными.Получатели.АвтоЗаполнение = Ложь;
		Сумма1 = Набор[0].Ресурс1;  
		
		СуммаДельта = НачСуммаДельта;
		
		//ЗаписьЖурналаРегистрации("ОшибкаИтогов.ИзменениеДвижений.Начало", УровеньЖурналаРегистрации.Ошибка,,
		//,"Сумма = Сумма + СуммаДельта (" 
		//+ сокрлп(Сумма1 + НачСуммаДельта) + " = " 
		//+ сокрлп(Сумма1) + " + " 
		//+ сокрлп(СуммаДельта) + ")");  
		
		Пока СуммаДельта < КонСуммаДельта Цикл    
			СуммаДельта = СуммаДельта + Шаг;
			Набор[0].Ресурс1 = Сумма1 + СуммаДельта;
			Набор.Записать();
		КонецЦикла;                
		
		СуммаДельта = КонСуммаДельта;
		Набор[0].Ресурс1 = Сумма1 + СуммаДельта;
		Набор.Записать();
		
		//ЗаписьЖурналаРегистрации("ОшибкаИтогов.ИзменениеДвижений.Окончание", УровеньЖурналаРегистрации.Ошибка,,
		//,"Сумма = Сумма + СуммаДельта (" 
		//+ сокрлп(Сумма1 + СуммаДельта) + " = " 
		//+ сокрлп(Сумма1) + " + " 
		//+ сокрлп(СуммаДельта) + ")");      
		
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ТестИсправленный(Команда)
	ТестИсправленныйНаСервере(Объект.Дата);
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ТестВоспроизведенияОшибкиНаСервере(Дата)
	ДатаТеста = НачалоМесяца(Дата);                  
	НачСуммаДельта = -1000;
	Шаг = 10;                  
	КонСуммаДельта = 0;
	Запрос = Новый Запрос("ВЫБРАТЬ ПЕРВЫЕ 1
	                      |	РегистрНакопления1.Регистратор КАК Регистратор
	                      |ИЗ
	                      |	РегистрНакопления.РегистрНакопления1 КАК РегистрНакопления1
	                      |ГДЕ
	                      |	РегистрНакопления1.Период < &Дата
	                      |
	                      |УПОРЯДОЧИТЬ ПО
	                      |	РегистрНакопления1.Период УБЫВ");
	Запрос.УстановитьПараметр("Дата", ДобавитьМесяц(ДатаТеста, 1));
	Выборка = Запрос.Выполнить().Выбрать();                          
	
	Набор = РегистрыНакопления.РегистрНакопления1.СоздатьНаборЗаписей();
	Набор.Отбор.Регистратор.Использование = Истина; //вроде и так Истина  
	
	ПереставитьГраницуВФоне.ПереставитьГраницуВФонеСБлокировкой(ДобавитьМесяц(КонецМесяца(ДатаТеста), -1));
	
	Парам = Новый Массив;    
	Парам.Добавить(КонецМесяца(ДатаТеста));
	ФоновыеЗадания.Выполнить("ПереставитьГраницуВФоне.ПереставитьГраницуВФоне", Парам);
	
	Если Выборка.Следующий() Тогда
		Набор.Отбор.Регистратор.Значение = Выборка.Регистратор;
		Набор.Прочитать();     
		Набор.ОбменДанными.Загрузка = Истина;
		Набор.ОбменДанными.Получатели.АвтоЗаполнение = Ложь;
		Сумма1 = Набор[0].Ресурс1;  
		
		СуммаДельта = НачСуммаДельта;
		
		//ЗаписьЖурналаРегистрации("ОшибкаИтогов.ИзменениеДвижений.Начало", УровеньЖурналаРегистрации.Ошибка,,
		//,"Сумма = Сумма + СуммаДельта (" 
		//+ сокрлп(Сумма1 + НачСуммаДельта) + " = " 
		//+ сокрлп(Сумма1) + " + " 
		//+ сокрлп(СуммаДельта) + ")");  
		
		Пока СуммаДельта < КонСуммаДельта Цикл    
			СуммаДельта = СуммаДельта + Шаг;
			Набор[0].Ресурс1 = Сумма1 + СуммаДельта;
			Набор.Записать();
		КонецЦикла;                
		
		СуммаДельта = КонСуммаДельта;
		Набор[0].Ресурс1 = Сумма1 + СуммаДельта;
		Набор.Записать();
		
		//ЗаписьЖурналаРегистрации("ОшибкаИтогов.ИзменениеДвижений.Окончание", УровеньЖурналаРегистрации.Ошибка,,
		//,"Сумма = Сумма + СуммаДельта (" 
		//+ сокрлп(Сумма1 + СуммаДельта) + " = " 
		//+ сокрлп(Сумма1) + " + " 
		//+ сокрлп(СуммаДельта) + ")");      
		
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ТестВоспроизведенияОшибки(Команда)
	ТестВоспроизведенияОшибкиНаСервере(Объект.Дата);
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	Объект.Дата = Дата(2022,09,15);
КонецПроцедуры
