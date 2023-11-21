.include "m128def.inc"
.device ATmega128

.equ LED_PORT = PORTB ; Регистр для управления светодиодами

.equ Number = 10 ; Длина массива
.def temp = R16
.def tcnt = R17
.def tg = R20

.def Delay = R21 ; переменная задержки
.def Delay2 = R22 ; задержка
.def Delay3 = R23 ; задержка
.equ Const5 = 13; константа на 1 сек
.equ Const6 = 27; константа на 2 сек
.equ Const7 = 120; константа на 3 сек

.dseg
.org $100
massiv: .BYTE Number

.org $140
massiv2: .BYTE Number

.cseg
ldi R16, 0xFF ; Установить R16 = $FF
out DDRB, R16 ; Настроить все пины порта B на выход
out PORTB, R16 ; Установить все светодиоды в выключенное состояние
out PORTD,  R16



SW_START_PROGRAM:
   sbis PIND,1;кнопка SW0 нажата? Если да, то ниже:
   jmp READ_EEP_ARRAY
   jmp SW_START_PROGRAM
   
   
READ_EEP_ARRAY:
   ldi R17, 0xFE ; Установить R17 = 0xFF для включения всех светодиодов
   out LED_PORT, R17 ; Включить все светодиоды

   ldi tcnt, Number
   
	ldi ZL, low (table_1<<1) ; в R30 занести младший байт адреса 
	; table_1*2.
	ldi ZH, high (table_1<<1) ; в R31 занести старший байт адреса 
	; table_1*2.
   
   ldi XL, low (massiv) ; в R26 занести младший байт адреса
   ; области massiv.
   ldi XH, high (massiv) ; в R27 занести старший байт адреса 
   ; области massiv.
   
   loop_read_eep:
		lpm temp, Z+
      st X+, temp ; перезапись содержимого регистра R16 в ячейки 
      ; памяти данных по адресу из пары X,
      ; затем нарастить пару Х (XH:XL) на 1.
      dec tcnt ; декрементировать счетчик на 1
      brne loop_read_eep
   
   
call delay_3sec

DIV_S:
   ldi R17, 0xFC ; Установить R17 = 0xFF для включения всех светодиодов
   out LED_PORT, R17 ; Включить все светодиоды
   ;реализовать деление массива из data memory
   
   ldi tg, Number ; Загрузить счетчик
   ldi XL, low (massiv) ; Загрузить младший байт адреса массива
   ldi XH, high (massiv) ; Загрузить старший байт адреса массива

   ldi YL, low (massiv2) ; Загрузить младший байт адреса массива
   ldi YH, high (massiv2) ; Загрузить старший байт адреса массива
   
   ;цикл деления
   loop_div:
      ld R17, X+ ; Загрузить значение из массива
      ldi R16, 6 ; Загрузить делитель
      call div8_8 ; Вызвать процедуру деления

      neg R18
      st Y+, R18 ; Сохранить результат обратно в массив
      dec tg ; Уменьшить счетчик
      brne loop_div ; Повторить цикл, пока счетчик не станет равным нулю
   
   

call delay_3sec

WRITE_RES_EEP:
   ldi R17, 0xF8 ; Установить R17 = 0xFF для включения всех светодиодов
   out LED_PORT, R17 ; Включить  светодиоды
   
   ldi tcnt, Number

   ldi R24, low(array_eep) ; младшая часть
   ldi R25, high(array_eep) ; старшая часть

   ldi XL, low (massiv2) ; Загрузить младший байт адреса массива
   ldi XH, high (massiv2) ; Загрузить старший байт адреса массива
   
   loop_eep_write:
      ld temp, X+ ; выгрузка байта данных из области констант
      call EEPROM_write
      adiw R24, 1
      dec tcnt
      brne loop_eep_write ; повторяем цикл пока tcnt не 0

call delay_3sec

D_OUT:
	ldi XL, low (massiv2) ; Загрузить младший байт адреса массива
	ldi XH, high (massiv2) ; Загрузить старший байт адреса массива
	ldi tcnt, Number

	loop_d_out:
		ld temp, X+ ; выгрузка байта данных из области констант
		com temp
		out LED_PORT, temp
		call delay_1sec

		ldi R17, 0xFF ; Установить R17 = 0xFF для включения всех светодиодов
		out LED_PORT, R17 ; Включить  светодиоды
		call delay_2sec

		dec tcnt
		brne loop_d_out

quit: rjmp quit

table_1:
;.db $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA
.db 12, 22, 33, 44, 55, 66, 77, 11, 11, 11


;**** программно реализованная временная задержка
delay_1sec:
ldi Delay2, Const5 ; установить регистр R18 равным 5
ldi Delay3, Const5
eor Delay, Delay ; очистка регистра R17

DLY: dec Delay
brne DLY
dec Delay2
brne DLY
dec Delay3
brne DLY
ret ; Вернуться из функции задержки


;**** программно реализованная временная задержка
delay_2sec:
ldi Delay2, Const6 ; установить регистр R18 равным 5
ldi Delay3, Const6
eor Delay, Delay ; очистка регистра R17
jmp DLY
ret ; Вернуться из функции задержки

;**** программно реализованная временная задержка
delay_3sec:
ldi Delay2, Const7 ; установить регистр R18 равным 5
ldi Delay3, Const7
eor Delay, Delay ; очистка регистра R17
jmp DLY
ret ; Вернуться из функции задержки


EEPROM_read:
sbic EECR,EEWE; Ожидать окончания выполнения предыдущей 
; операции записи
rjmp EEPROM_read
out EEARH, R25 ; Переписать содержимое регистров
; (R18:R17) в регистр адреса EEPROM (EEARH:EEARL).
out EEARL, R24 ; 
sbi EECR,EERE ; Установить в регистре EECR флаг EERE в 
; состояние лог. 1 – активировать считывание байта 
; данных из выбранной ячейки EEPROM в регистр EEDR. 
in R16,EEDR ; переписать байт данных из регистра EEDR
; регистр R16
ret ; возврат из подпрограммы EEPROM_read

EEPROM_write:
sbic EECR,EEWE ; Ожидать окончания выполнения 
rjmp EEPROM_write ; предыдущей операции записи 
cli ; clear interrupt flag (запретить все прерывания)
out EEARH, R25 ; Переписать содержимое регистров(R18:R17) 
out EEARL, R24 ; в регистр адреса EEPROM (EEARH:EEARL).
out EEDR, R16 ; Переписать содержимое (R16) регистра 
; данных EEPROM
sbi EECR, EEMWE; Установить в регистре EECR флаг EEMWE в 
 ; состояние лог. 1
sbi EECR,EEWE ; Установить в регистре EECR флаг EEWE в 
; состояние лог. 1 – активировать запись 
; байта данных в EEPROM в выбранную ячейку.
sei ; enable interrupt (разрешить все прерывания,
; незаблокированные в источниках прерываний).
ret ; возврат из подпрограммы EEPROM_write

div8_8:   
     clr   R18       ;очищаем R18 при входе
     sub   R17,R16   ;производим вычитание R17-R16
     inc   R18         
     brcc  PC-2      ;до тех пор пока разность R17-R16 > 0
     dec   R18       ;когда разность R17-R16 < 0
     add   R17,R16   ;восстанавливаем R17 и корректируем R18
     ret     

.eseg
.org 0
array_eep: 
.byte 10
