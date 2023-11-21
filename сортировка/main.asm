.include "m128def.inc" 
.device ATmega128 
.equ LED_PORT = PORTB ; Регистр для управления светодиодами 

.equ Number = 10 ; Длина массива 
.def temp = R16 
.def temp2 = R21 
.def tcnt = R20 
.def tcntt = R22 
.def swapTemp = R23 

.def Delay = R17 ; переменная задержки 
.def Delay2 = R18 ; задержка 
.def Delay3 = R19 ; задержка 
.equ Const5 = 8; константа на 1/5 сек 
.equ Const6 = 32; константа на 4/5 сек 
.equ Const7 = 120; константа на 3 сек 
  

.dseg 
.org $100 
massiv: .BYTE Number 

.cseg 

ldi R16, 0xFF ; Установить R16 = $FF 
out DDRB, R16 ; Настроить все пины порта B на выход 
out PORTB, R16 ; Установить все светодиоды в выключенное состояние 
out PORTD,  R16 



; поставьте мне баллы пжпжпжпжпжпж :^)
INITIAL_EEP:
	ldi ZL, low (table_1<<1) ; в ZL занести младший байт адреса  
	; table_1*2. 
	ldi ZH, high (table_1<<1) ; в ZH занести старший байт адреса  
	; table_1*2. 
	ldi R24, low(start_eep_arr) ; в R24 занести младший байт адреса  
	ldi R25, high(start_eep_arr) ; в R25 занести старший байт адреса  
	ldi tcnt, Number ; счетчик
	loop_write_eep:
		lpm temp2, Z+
		call EEPROM_write
		adiw R24, 1 ; переход к след элементу записи EEPROM
		dec tcnt ; уменьшить значение счетцика на 1
		brne loop_write_eep ; повторять пока tcnt не 0

SW_ON: 
sbis PIND,1;кнопка SW1 нажата? Если да, то ниже: 
jmp READ_ARRAY 
jmp SW_ON 

; запись данных из EEPROM memory в DATA memory
READ_ARRAY: 
	ldi R17, 0xFE ; Установить R17 = 0xFE для включения 0 светодиода
	out LED_PORT, R17 ; Включить все светодиоды 

	ldi XL, low (massiv) ; в XL занести младший байт адреса 
	; области massiv. 
	ldi XH, high (massiv) ; в XH занести старший байт адреса  
	; области massiv. 
	ldi R24, low (start_eep_arr) ; в R24 занести младший байт адреса  
	ldi R25, high (start_eep_arr) ; в R25 занести старший байт адреса  
	ldi tcnt, Number 

loop_read_eep:  
	call EEPROM_read
	adiw R24, 1 
	st X+, temp2 ; перезапись содержимого регистра R16 в ячейки  
	; памяти данных по адресу из пары X, 
	; затем нарастить пару Х (XH:XL) на 1. 
	dec tcnt ; декрементировать счетчик на 1 
	brne loop_read_eep ; повторять цикл, пока счетчик не станет равным 0. 

call delay_3sec 

;сортировка по убыванию ;)
SORT_ARRAY: 
   ldi R17, 0xFC ; Установить R17 = 0xFC для включения 0-1 светодиодов 
   out LED_PORT, R17 ; Включить светодиоды 
   ldi tcntt, Number-1 ; Инициализируем счетчик для внешнего цикла 

loop5: 
mov tcnt, tcntt ; Инициализируем счетчик для внутреннего цикла 
ldi XL, low (massiv) ; Загружаем младший байт адреса начала массива 
ldi XH, high (massiv) ; Загружаем старший байт адреса начала массива 

loop6: 
  ld temp, X+ ; Загружаем текущий элемент 
  ld temp2, X ; Загружаем следующий элемент 
  cp temp, temp2 ; Сравниваем элементы 
  brge no_swap ; Если текущий элемент больше или равен следующему, переходим к NO_SWAP 
  st X, temp ; Если текущий элемент меньше следующего, меняем их местами 
  st -X, temp2 

  adiw X, 1 ; Увеличиваем X, чтобы указать на следующий элемент 

no_swap: 
  dec tcnt ; Уменьшаем счетчик внутреннего цикла 
  brne loop6 ; Если счетчик не равен нулю, повторяем внутренний цикл 

dec tcntt ; Уменьшаем счетчик внешнего цикла 
brne loop5 ; Если счетчик не равен нулю, повторяем внешний цикл 
    

call delay_3sec 
  

WRITE_ARRAY: 
   ldi R17, 0xF8 ; Установить R17 = 0xF8 для включения 0-2 светодиодов 
   out LED_PORT, R17 ; Включить светодиоды 
   ldi tcnt, Number ; счетчик = 10
   ldi R24, low(table_res) 
   ldi R25, high(table_res) 
   ldi XL, low (massiv) ; в XL занести младший байт адреса 
   ; области massiv. 
   ldi XH, high (massiv) ; в XH занести старший байт адреса  
   ; области massiv. 

   loop2: 
      ld temp2, X+ 
      call EEPROM_write 
      adiw R24, 1 
      dec tcnt ; уменьшить значение счетцика на 1
      brne loop2 ; повторять пока tcnt не 0

reset_flash: 

call delay_3sec 

ldi XL, low (massiv) ; в XL занести младший байт адреса 
; области massiv. 
ldi XH, high (massiv) ; в XH занести старший байт адреса  
; области massiv. 
ldi tcnt, Number ; счетчик

FLASHING: 

   ld R17, X+ ; Установить R17  для вывода элемента массива 
   com R17 ; проинвертировать
   out LED_PORT, R17 ; Вывести на светодиоды элемент массива
   call delaySkvaz1 ; Вызвать функцию задержки 

   ldi R17, 0xFF ; Установить R17 = 0xFF для выключения всех светодиодов 
   out LED_PORT, R17 ; Выключить все светодиоды 
   call delaySkvaz2 ; Вызвать функцию задержки 

   dec tcnt ; уменьшить значение счетцика на 1
   brne FLASHING ; повторять пока tcnt не 0

   rjmp reset_flash ; Бесконечный цикл 
  

;**** программно реализованная временная задержка 
delaySkvaz1: 
ldi Delay2, Const5 ; установить регистр Delay2
ldi Delay3, Const5 
eor Delay, Delay ; очистка регистра

DLY: dec Delay 
brne DLY 
dec Delay2 
brne DLY 
dec Delay3 
brne DLY 
ret ; Вернуться из функции задержки 

;**** программно реализованная временная задержка 
delaySkvaz2: 
ldi Delay2, Const6 ; установить регистр Delay2
ldi Delay3, Const6 
eor Delay, Delay ; очистка регистра  
jmp DLY 
ret ; Вернуться из функции задержки 

;**** программно реализованная временная задержка 

delay_3sec: 
ldi Delay2, Const7 ; установить регистр Delay2
ldi Delay3, Const7 
eor Delay, Delay ; очистка регистра
jmp DLY 
ret ; Вернуться из функции задержки 
  
table_1: 
;.db $11, $22, $33, $44, $55, $66, $77, $00, $00, $00 
.db 11, -22, 33, 44, -55, 66, 77, 88, 99, 00, 00, 00

EEPROM_write: 
sbic EECR,EEWE ; Ожидать окончания выполнения  
rjmp EEPROM_write ; предыдущей операции записи  
cli ; clear interrupt flag (запретить все прерывания) 
out EEARH, R25 ; Переписать содержимое регистров(R25:R24)  
out EEARL, R24 ; в регистр адреса EEPROM (EEARH:EEARL). 
out EEDR, R21 ; Переписать содержимое (R21) регистра  
; данных EEPROM 
sbi EECR, EEMWE; Установить в регистре EECR флаг EEMWE в  
; состояние лог. 1 
sbi EECR,EEWE ; Установить в регистре EECR флаг EEWE в  
; состояние лог. 1 – активировать запись  
; байта данных в EEPROM в выбранную ячейку. 
sei ; enable interrupt (разрешить все прерывания, 
; незаблокированные в источниках прерываний). 
ret ; возврат из подпрограммы EEPROM_write 

EEPROM_read:
sbic EECR,EEWE; Ожидать окончания выполнения предыдущей 
; операции записи
rjmp EEPROM_read
out EEARH, R25; Переписать содержимое регистров
; (R25:R24) в регистр адреса EEPROM (EEARH:EEARL).
out EEARL, R24; 
sbi EECR,EERE ; Установить в регистре EECR флаг EERE в 
; состояние лог. 1 – активировать считывание байта 
; данных из выбранной ячейки EEPROM в регистр EEDR. 
in R21,EEDR ; переписать байт данных из регистра EEDR
; регистр R21
ret ; возврат из подпрограммы EEPROM_read

.eseg 
.org $34 
table_res:  
.byte 10 

.org 0 
start_eep_arr:  
.byte 10 