
.include "m128def.inc"
.device ATmega128
.equ LED_PORT = PORTB ; Регистр для управления светодиодами 

.equ Number = 12 ; Длина массива 
.def temp = R16 
.def temp2 = R21 
.def tcnt = R20 
.def tcntt = R22 
.def swapTemp = R23 

.def Delay = R17 ; переменная задержки 
.def Delay2 = R18 ; задержка 
.def Delay3 = R19 ; задержка 
.equ Const5 = 40; константа на 1 сек 


;***** Инициализация
.org $0000
RESET:
jmp Start
.org $001A
rjmp T1_comp ;Совпадение таймера-счетчика T1
.org $001C 
rjmp T1_ovf


T1_comp: 
push Temp
ser Temp
out PORTB, Temp
pop temp
reti

T1_ovf:
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



READ_ARRAY: 
	ldi R17, 0xFE ; Установить R17 = 0xFE для включения 0 светодиода
	out LED_PORT, R17 ; Включить все светодиоды 

	ldi XL, low (massiv2) ; в XL занести младший байт адреса 
	; области massiv. 
	ldi XH, high (massiv2) ; в XH занести старший байт адреса  
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
ldi XL, low (massiv2) ; Загружаем младший байт адреса начала массива 
ldi XH, high (massiv2) ; Загружаем старший байт адреса начала массива 

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



; инициализация таймера-счетчика
clr Temp
out TCNT1H, Temp
out TCNT1L, Temp
clr tcntt
 

ldi temp, $00
out OCR1BH, tcntt
out OCR1BL, temp

; Настройка TCCR1A
ldi Temp, (0<<COM1A1)+(0<<COM1A0)+ (0<<COM1B1)+(0<<COM1B0)+ (0<<COM1C1)+(0<<COM1C0)+ (0<<WGM11)+(0<<WGM10)
out TCCR1A, Temp
; Настройка TCCR1C
ldi Temp, (1<<FOC1A)+(0<<FOC1B)+ (1<<FOC1C);
sts TCCR1C, Temp
; Настройка TCCR1B
ldi Temp, (0<<ICNC1)+(1<<ICES1)+(0<<WGM13)+(0<<WGM12)+(0<<CS12)+ (0<<CS11)+(1<<CS10); Fosc/64
out TCCR1B, Temp ; в результате таймер-счетчик1 настроен 
; в требуемый режим счета и тут же начинает считать!!!!
ldi temp, (1<<TOIE1)+ (1<<OCIE1B)
out TIMSK, temp
; разрешение всех прерываний
Sei
; основная программа

;call delay_3sec


WRITE_ARR:

	ldi tcnt, Number+1
	LDI ZL, Low(massiv2) 
	LDI ZH, High(massiv2)

OUTED_LOOP:
clr tcntt
ld Temp, Z+ ; выгрузка байта данных из области констант

out OCR1BH, temp
out OCR1BL, tcntt

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
massiv2: .BYTE Number

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
      
table_1:
.db 11, 22, 33, 44, 55, 66, 77, 88, 99, 98, 97, 96


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
.org 0 
start_eep_arr:  
.byte 10

