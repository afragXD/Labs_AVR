;============================================================
;***** Тест таймера-счетчика 
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
.equ   Const6  = 13    ; константа 1/3 сек
.equ   Const7  = 27    ; константа 2/3 сек

.equ Const8 = 32 ; константа 8
.equ Number = 12 ; Длина массива

;***** Инициализация
.org $0000
RESET:
jmp Start
.org $001C
jmp T0_ovf

T0_ovf: 
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

	ldi R21, 0x7F ; Установить R17 = 0xFE для включения 0 светодиода
	out PORTB, R21; Включить все светодиоды

	LDI XL, Low(massiv2) 
	LDI XH, High(massiv2)
	;mov YL, XL
	;mov YH, XH
	LDI ZL, Low(table_1*2) 
        LDI ZH, High(table_1*2)
; переброс массива из FLASH в SRAM
	ldi temp, Number
  READ_ARR:  lpm 
        st X+, r0
	adiw ZL, 1
	dec temp
	brne READ_ARR

	call delay_3sec

DIV_S:
   ldi R17, 0x3F ; Установить R17 = 0xFF для включения всех светодиодов
   out PORTB, R17 ; Включить  светодиоды
   ; деление массива из data memory
   ldi tcnt, Number ; Загрузить счетчик
   ldi XL, low (massiv2) ; Загрузить младший байт адреса массива
   ldi XH, high (massiv2) ; Загрузить старший байт адреса массива

   ;цикл деления
   loop_div:
      ld R17, X ; Загрузить значение из массива
      ldi R16, 6 ; Загрузить делитель
      call div8_8 ; Вызвать процедуру деления
      neg R18
      st X+, R18 ; Сохранить результат обратно в массив
      dec tcnt ; Уменьшить счетчик
      brne loop_div ; Повторить цикл, пока счетчик не станет равным нулю

call delay_3sec

; инициализация таймера-счетчика

clr Temp
out TCNT1H, Temp
out TCNT1L, Temp
clr ztemp
 
ldi temp, $FF
out OCR1AH, ztemp
out OCR1AL, temp
ldi temp, $F5
out OCR1BH, ztemp
out OCR1BL, temp
ldi temp, $F5
sts OCR1CH, ztemp
sts OCR1CL, temp
; Настройка TCCR1A
ldi Temp, (1<<COM1A1)+(1<<COM1A0)+ (1<<COM1B1)+(1<<COM1B0)+ (1<<COM1C1)+(1<<COM1C0)+ (1<<WGM11)+(1<<WGM10)
out TCCR1A, Temp
; Настройка TCCR1C
ldi Temp, (0<<FOC1A)+(0<<FOC1B)+ (0<<FOC1C);
sts TCCR1C, Temp
; Настройка TCCR1B
ldi Temp, (0<<ICNC1)+(1<<ICES1)+(1<<WGM13)+(1<<WGM12)+(0<<CS12)+ (1<<CS11)+(1<<CS10); Fosc/64
out TCCR1B, Temp ; в результате таймер-счетчик1 настроен 
; в требуемый режим счета и тут же начинает считать!!!!
; разрешение всех прерываний
Sei
; основная программа

WRITE_ARR:

	ldi tcnt, Number+1
	LDI ZL, Low(massiv2) 
	LDI ZH, High(massiv2)

OUTED_LOOP:
clr ztemp
ld Temp, Z+ ; выгрузка байта данных из области констант

out OCR1BH, ztemp
out OCR1BL, temp

sts OCR1CH, ztemp
sts OCR1CL, temp

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
.org $180
massiv3: .BYTE Number
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
 
div8_8:   
     clr   R18       ;очищаем R18 при входе
     sub   R17,R16   ;производим вычитание R17-R16
     inc   R18         
     brcc  PC-2      ;до тех пор пока разность R17-R16 > 0
     dec   R18       ;когда разность R17-R16 < 0
     add   R17,R16   ;восстанавливаем R17 и корректируем R18
     ret     
      
table_1:
.db 11, 33, 44, 66,88, 111, 133, 155, 177, 199, 220, 250
