
.include "m128def.inc"
.device ATmega128
.def tcnt = R22
.def tcntt = R26
.def temp2 = R21
.def Temp = R16 ; временный регистр
.def Test = R17 ; временный тестовый регистр

.def ztemp = R20 ; временный регистр 

.def	Delay   = r23		;переменная задержки
.def	Delay2 = r24		;задержка
.def	Delay3 = r25		;задержка
.equ   Const5  = 120    ; константа 3 сек

.equ Const8 = 32 ; константа 8
.equ Number = 12 ; Длина массива

;***** Инициализация
.org $0000
RESET:
jmp Start

.org $0012
rjmp T2_comp ;Совпадение таймера-счетчика T2
.org $0014
rjmp T2_ovf

.org $0046

T2_comp: 
push Temp
ser Temp
out PORTB, Temp
pop temp
reti

T2_ovf:
push temp
clr Temp
out PORTB, Temp
pop temp

reti
; начало кода инициализации программы
Start: 
; инициализация стека
ldi temp, high(RAMEND)
out sph, temp
ldi temp, low(RAMEND)
out spl, temp

clr Temp
out DDRD, Temp
ser temp
out PORTD, Temp

LDI XL, Low(massiv) 
      LDI XH, High(massiv)
	mov YL, XL
	mov YH, XH
	LDI ZL, Low(My_Data*2) 
        LDI ZH, High(My_Data*2)
; переброс массива из FLASH в SRAM
	ldi temp, 16
  WRITE_7SEG:  lpm 
        st X+, r0
	adiw ZL, 1
	dec temp
	brne WRITE_7SEG

ser Temp
out DDRB, Temp
out PORTB, Temp
out DDRC, Temp     	;PORTС = все на выход, 0-е состояние выходов
out PORTD, Temp	;Подключить pull-up резисторы к разрядам 
; порта PORTD, все разряды которого настроить на вход.
out DDRA, Temp
out PORTA, Temp


ldi R22, low(Original_word)
ldi R23, high(Original_word)

ldi R17, $44
call EEPROM_write


READ_EEP:
	ldi R21, 0xFE
	out PORTB,  R21

	ldi R22, low(Original_word)
	ldi R23, high(Original_word)

	ldi XL, low(init_arr)
	ldi XH, high(init_arr)

	call EEPROM_read
	st X, R17

	call delay_3sec



SS:
	ldi R21, 0xFC
	out PORTB,  R21

	ldi ZL, low(res_arr)
	ldi ZH, high(res_arr)

SHIFT_L_4R:
		lsr R17
		lsr R17
		lsr R17
		lsr R17
		st Z+, R17

ld R17, X
SHIFT_L_4L:
	lsl R17
	lsl R17
	lsl R17
	lsl R17
	st Z+, R17

ld R17, X
SHIFT_R_4L:
	rol R17
	rol R17
	rol R17
	rol R17
	st Z+, R17

ld R17, X
SHIFT_R_4R:
	ror R17
	ror R17
	ror R17
	ror R17
	st Z+, R17

ld R17, X
SHIFT_A_4R:
	asr R17
	asr R17
	asr R17
	asr R17
	st Z+, R17

ld R17, X
SHIFT_A_4L:
	lsl R17
	lsl R17
	lsl R17
	lsl R17
	st Z+, R17

call delay_3sec

; инициализация таймера-счетчика 
clr Temp
out TCNT2, Temp
ldi Temp, 10
out OCR2, Temp
ldi Temp, 0
out PORTB, Temp
ldi Temp,(0<<FOC2)+(0<<COM21)+(0<<COM20)+(0<<WGM21)+(0<<WGM20)\
+(1<<CS22) +(0<<CS21)+(0<<CS20); f/128
out TCCR2, Temp ; в результате таймер-счетчик 2 настроен в 
; Разрешение запроса прерывания по переполнению 
ldi temp, (1<<TOIE2)+ (1<<OCIE2)
out TIMSK, temp
; режим «СТС» с инвертированием ОС2, таймер-счетчик тут же 
; начинает считать. Счет выполняется до момента, пока значение 
; TCNT2 не совпадёт с OCR2!!!!	
; глобальное разрешение прерываний
SEI
; основная программа

WRITE_ARR:

	ldi tcnt, Number+1
	LDI ZL, Low(res_arr) 
	LDI ZH, High(res_arr)

OUTED_LOOP:
clr ztemp
ld Temp, Z+ ; выгрузка байта данных из области констант

;ldi R19, $FF
mov R19, Temp
out OCR2, R19

com Temp

mov XL, YL	; скопировать значение YH:YL в XH:XL
       mov XH, YH
   mov r18, temp ; переписать код управления светодиодами в r18
   com r18	   ; проинвертировать числовой код	
   andi r18, 0x0f ; выделить младшую тетраду 
   add XL, r18	   ; добавить к XL числовой код – смещение 
   ; Тем самым был получен адрес кода изображения цифры
   ld r17, X	; загрузить в r17 код байта из ячейки с адресом 0x100+КодЦирфы
   rcall Print_Symbol ; вызвать подпрограмму загрузки кода изображения символа  
     mov XL, YL ; скопировать значение YH:YL в XH:XL (восстановить XH:XL)
     mov XH, YH
mov r18, temp
com r18
swap r18  ; сделать старшую тетраду младшей
andi r18, 0x0f
   add XL, r18
   ld r17, X
   rcall Print_Symbol 
rcall Strobe_LEDIND ; выполнить подпрограмму формирования строба обновления 
   ; индикаторов

call delay_3sec

dec tcnt
brne OUTED_LOOP
call delay_3sec
jmp WRITE_ARR

loop: rjmp loop ; бесконечный цикл

.dseg
.org 0x100
massiv: .BYTE 16  ; резервировать 16 байт в области внутренней памяти данных, 
; начиная с адреса 0x100
.org $140
init_arr: .BYTE  1

.org $180
res_arr: .BYTE  6
.cseg ; Представить в области памяти программ коды изображения цифр от 0 до F
; формат кода управления: 8 бит = децимальная точка + 7 бит кода управления 
; сегментами
My_Data: .dw 0x063F,0x4F5B,0x6D66,0x077D,0x6F7F, 0x7C77, 0x5E39, 0x7179; 
; подпрограмма загрузки кода изображения символа в БЦИ 
; вывод выполняется старшими разрядами вперед
Print_Symbol :
      push r17
      push r18
   ldi     r18, 8 ; установить R18 равным 8 (количество сегментов в ЦИ)
m3: rol  r17		; сдвиг над r17 влево кода символа с установкой флага
; переноса по состоянию выталкиваемого разряда
  brcc m1
rcall SetBit_LEDIND        ; загрузить бит, равный 1 
rjmp m2
m1:  rcall ClearBit_LEDIND ; загрузить бит, равный 0
m2: dec r18	; декрементировать счетчик 
	brne m3 ; повторять действия до тех пор, пока счетчик не станет равным 0
      pop r18
      pop r17
ret
	//==================================================
SetBit_LEDIND:
;**** записать единицу по входу DS в сдвиговый регистр
    sbi PORTC, PC2 ; DS = 1
	sbi PORTC, PC1 ; SH_CP = 1
	cbi PORTC, PC1 ; SH_CP = 0
      ret
ClearBit_LEDIND:
;**** записать ноль по входу DS в сдвиговый регистр
    cbi PORTC, PC2 ; DS = 0
	sbi PORTC, PC1 ; SH_CP = 1
	cbi PORTC, PC1 ; SH_CP = 0
      ret
Strobe_LEDIND:
;**** сформировать строб перезаписи содержимого сдвигового регистра в 
; параллельный выходной регистр с целью отображения загруженного кода на 
; индикаторе
	sbi PORTC, PC0 ; ST_CP = 1
	cbi PORTC, PC0 ; ST_CP = 0
      ret
 
delay_3sec:
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
 
EEPROM_write:
sbic EECR,EEWE ; Ожидать окончания выполнения
rjmp EEPROM_write ; предыдущей операции записи
cli ; clear interrupt flag (запретить все прерывания)
out EEARH, R23;Переписать содержимое регистров(R23:R22)
out EEARL, R22; в регистр адреса EEPROM (EEARH:EEARL).
out EEDR, R17; Переписать содержимое (R17) регистра
; данных EEPROM
sbi EECR, EEMWE; Установить в регистре EECR флаг EEMWE в
; состояние лог. 1
sbi EECR,EEWE ; Установить в регистре EECR флаг EEWE в
; состояние лог. 1 – активировать запись
; байта данных в EEPROM в выбранную ячейку.
sei ; enable interrupt (разрешить все прерывания,
; незаблокированные в источниках прерываний).
ret ;возврат из подпрограммы EEPROM_write

EEPROM_read:
sbic EECR,EEWE; Ожидать окончания выполнения предыдущей
; операции записи
rjmp EEPROM_read
out EEARH, R23 ; Переписать содержимое регистров
; (R23:R22) в регистр адреса EEPROM (EEARH:EEARL).
out EEARL, R22 ;
sbi EECR,EERE ; Установить в регистре EECR флаг EERE в
; состояние лог. 1 – активировать считывание байта
; данных из выбранной ячейки EEPROM в регистр EEDR.
in R17,EEDR ; переписать байт данных из регистра EEDR
; регистр R17
ret ; возврат из подпрограммы EEPROM_read

.ESEG
.org $0
Original_word: .BYTE  1
