.include "m128def.inc"
.device ATmega128

.equ LED_PORT = PORTB ; Регистр для управления светодиодами
.equ Number = 10 ; Длина массива

.def counter_sec_u = r17
.def counter_sec_t = r18
.def counter_min_u = r19
.def counter_min_t = r20
.equ delay_sec = 35
.equ delay_min = 29
.def temp = r15
.def tmp = r16
.def tmp2 = r26
.def mask = r27
.equ start_digit = 0x01
.def digit = r21
.def which_digit = r22
.def strob_flag = r23

.def Delay = R24 ; переменная задержки
.def Delay2 = R25 ; задержка
.def Delay3 = R28 ; задержка

.equ Const5 = 6 ; константа 

.dseg
.org $100
massiv: .BYTE Number

.org $140
massiv2: .BYTE Number

.CSEG
.org $0000 ;????????? ??p?? ?p??p????
rjmp Start ;??p???? ? p?????? ????? ?p??p???? (?????p Reset)

.org $0012
rjmp SPI_transmit ;?????????? ???????/???????? T2
.org $0018
rjmp add_min ;?????????? "?" ???????/???????? T1

.org $001E
rjmp add_sec;?????????? ???????/???????? T0
.org $0020
reti;???????????? ???????/???????? T0

.org $0022
rjmp SPI_strob ;???????? ?? SPI ?????????

.cseg

Start:
;инициализация стека
init_stack:
ldi tmp,High(RAMEND)
out SPH,tmp
ldi tmp,Low(RAMEND)
out SPL,tmp

;включение портов
ser tmp
out DDRB, tmp
out DDRD, tmp
sts DDRG, tmp

out PORTB, tmp

out PORTC, tmp


READ_ARRAY:
   ldi digit, Number
	ldi ZL, low (table_1<<1) ; в ZL занести младший байт адреса 
	; table_1*2.
	ldi ZH, high (table_1<<1) ; в ZH занести старший байт адреса 
	; table_1*2.
   ldi XL, low (massiv) ; в XL занести младший байт адреса
   ; области massiv.
   ldi XH, high (massiv) ; в  XH занести старший байт адреса 
   ; области massiv.
   loop_read:
		lpm tmp, Z+
      st X+, tmp ; перезапись содержимого регистра R16 в ячейки 
      ; памяти данных по адресу из пары X,
      ; затем нарастить пару Х (XH:XL) на 1.
      dec digit ; декрементировать счетчик на 1
      brne loop_read ; Повторить цикл, пока счетчик не станет равным нулю
 
call delay_x

DIV_S:
   ; деление массива из data memory
   ldi digit, Number ; Загрузить счетчик
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
      dec digit ; Уменьшить счетчик
      brne loop_div ; Повторить цикл, пока счетчик не станет равным нулю


;инициализация SPI
ldi tmp, 0b11011110
out SPCR, tmp
ldi tmp, (0<<SPI2X)
out SPSR, tmp

;инициализация таймеров
;Т0
clr tmp
out TIMSK, tmp

in tmp, ASSR
sbr tmp, (1<<AS0)
out ASSR, tmp

clr tmp
out TCNT0, tmp
ldi tmp, delay_sec
out OCR0, tmp
ldi tmp, 0b00011111
out TCCR0, tmp

wait_0:
in tmp, ASSR
andi tmp, (1<<TCN0UB)+(1<<OCR0UB)+(1<<TCR0UB)
brne wait_0

in tmp, TIFR
ldi tmp, 0b00000011
out TIFR, tmp

;T2
ldi tmp, 8
out OCR2, tmp
ldi tmp, 0b00101101
out TCCR2, tmp

;T1, канал А
ldi tmp, 0x00
out OCR1AH, tmp
ldi tmp, delay_min
out OCR1AL, tmp
ldi tmp, 0b10000000
out TCCR1A, tmp
ldi tmp, 0b01001110
out TCCR1B, tmp

;разрешение прерываний по сравнению на таймерах 0, 1, 2
ldi tmp, 0b10010010
out TIMSK, tmp

ldi ZL, low (massiv2) ; Загрузить младший байт адреса массива
	ldi ZH, high (massiv2) ; Загрузить старший байт адреса массива
	ldi tmp2, Number

;глобальное разрешение прерываний
sei
;ldi R22, $44
ld R22, Z

mov tmp, R22
	andi tmp, 0x0F

mov counter_sec_u, tmp

mov tmp, R22
	swap tmp
	andi tmp, 0x0F
mov counter_sec_t, tmp


ldi counter_min_u, 12
ldi counter_min_t, 13

;выбор первой цифры (единицы секунд)
ldi which_digit, 0x08

;запрет инициализации входов регистров
sbi PORTD, 1
;запрет выдачи информации с регистров
cbi PORTD, 2
;признак передачи последнего байта
ldi strob_flag, 0

;инициализация маски двоеточия для мигания
ldi mask, 0x80

;основной цикл
loop:


in tmp2, TCCR0
cp tmp, tmp2
breq after_check
out TCCR0, tmp

after_check:

call delay_x


rjmp loop


;прерывание 
add_sec:
push tmp
push tmp2
lds tmp,SREG
push tmp
 



;возврат из прерывания
return_sec:

ldi tmp2, 0x80
eor mask, tmp2

pop tmp
sts SREG, tmp
pop tmp2
pop tmp
reti


;прерывание
add_min:
push tmp
push tmp2
lds tmp,SREG
push tmp


;возврат из прерывания
return_min:
pop tmp
sts SREG, tmp
pop tmp2
pop tmp
reti


;начало передачи
SPI_transmit:
push tmp
push tmp2
lds tmp,SREG
push tmp

cpi strob_flag, 0
brne exit_transmit

cpi which_digit, 8
brne s_t
mov digit, counter_sec_u
ldi which_digit, start_digit
rjmp to_output_2
s_t:
cpi which_digit, 1
brne m_u
mov digit, counter_sec_t
rjmp to_output_1
m_u:
cpi which_digit, 2
brne m_t
mov digit, counter_min_u
rjmp to_output_1
m_t:
mov digit, counter_min_t

to_output_1:
lsl which_digit

to_output_2:
out SPDR, which_digit
inc strob_flag
nop
nop

exit_transmit:

pop tmp
sts SREG, tmp
pop tmp2
pop tmp
reti


;обновление индикации и инициализация передачи второго байта
SPI_strob:
push tmp
push tmp2
lds tmp,SREG
push tmp

cpi strob_flag, 1
breq second_transmit
sbi PORTD, 2
nop
cbi PORTD, 2
ldi strob_flag, 0
rjmp after_strob

second_transmit:
rcall output
inc strob_flag

after_strob:

pop tmp
sts SREG, tmp
pop tmp2
pop tmp
reti


;перевод цифры в символ и выдача на интерфейс
output:
push tmp
push tmp2
lds tmp,SREG
push tmp

cpi digit, 0
brne d1
ldi tmp, 0xBF
rjmp exit

d1:
cpi digit, 1
brne d2
ldi tmp, 0x86
rjmp exit

d2:
cpi digit, 2
brne d3
ldi tmp, 0xDB
rjmp exit

d3:
cpi digit, 3
brne d4
ldi tmp, 0xCF
rjmp exit

d4:
cpi digit, 4
brne d5
ldi tmp, 0xE6
rjmp exit

d5:
cpi digit, 5
brne d6
ldi tmp, 0xED
rjmp exit

d6:
cpi digit, 6
brne d7
ldi tmp, 0xFD
rjmp exit

d7:
cpi digit, 7
brne d8
ldi tmp, 0x87
rjmp exit

d8:
cpi digit, 8
brne d9
ldi tmp, 0xFF
rjmp exit

d9:
cpi digit, 9
brne d10
ldi tmp, 0x6F
rjmp exit

d10:
cpi digit, 10
brne d11
ldi tmp, 0x77
rjmp exit

d11:
cpi digit, 11
brne d12
ldi tmp, 0x7C
rjmp exit

d12:
cpi digit, 12
brne d13
ldi tmp, 0x39
rjmp exit

d13:
cpi digit, 13
brne d14
ldi tmp, 0x5E
rjmp exit

d14:
cpi digit, 14
brne d15
ldi tmp, 0x79
rjmp exit

d15:
ldi tmp, 0x71

exit:
com tmp
add tmp, mask
out SPDR, tmp
nop
nop

pop tmp
sts SREG, tmp
pop tmp2
pop tmp
ret

;защита от выскакивания указателя интрукций вне программы
end: rjmp end

table_1:
.db 12, 22, 33, 44, 55, 66, 77, 11, 11, 11

;**** программно реализованная временная задержка
delay_x:
ldi Delay2, Const5 ; установить регистр R18
ldi Delay3, Const5
eor Delay, Delay ; очистка регистра R17
DLY: dec Delay
Brne DLY
dec Delay2
brne DLY
dec Delay3
brne DLY
ret

div8_8:   
     clr   R18       ;очищаем R18 при входе
     sub   R17,R16   ;производим вычитание R17-R16
     inc   R18         
     brcc  PC-2      ;до тех пор пока разность R17-R16 > 0
     dec   R18       ;когда разность R17-R16 < 0
     add   R17,R16   ;восстанавливаем R17 и корректируем R18
     ret     
