.include "m128def.inc"
.device ATmega128

.def counter_sec_u = r17
.def counter_sec_t = r18
.def counter_min_u = r19
.def counter_min_t = r20
.equ delay_sec = 3
.equ delay_min = 3
.def tmp = r16
.def tmp2 = r26
.def mask = r27
.equ start_digit = 0x01
.def digit = r21
.def which_digit = r22
.def strob_flag = r23

.def Delay = R24 ; переменная задержки
.def Delay2 = R25 ; задержка
.equ Const5 = 250 ; константа 

.CSEG
.org $0000 
rjmp Start 

.org $0012
rjmp SPI_transmit 

.org $0018
rjmp add_min

.org $001E
rjmp add_sec

.org $0022
rjmp SPI_strob 

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

;глобальное разрешение прерываний
sei

;зануление регистров для счёта времени
ldi counter_sec_u, 12
ldi counter_sec_t, 0
ldi counter_min_u, 0
ldi counter_min_t, 0

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

;**** программно реализованная временная задержка
ldi Delay2, Const5 ; установить регистр R18 равным 5
eor Delay, Delay ; очистка регистра R17
DLY: dec Delay
Brne DLY
dec Delay2
brne DLY

rjmp loop


;прерывание на добавление секунд
add_sec:
push tmp
push tmp2
lds tmp,SREG
push tmp

sbis PINC, PC0
call CLEAR_TIMER


sbis PINC, PC1
jmp START_SEC
jmp return_sec
 
START_SEC:
;проверка, не достигли ли секунды предельного значения
cpi counter_sec_t, 9
brne before_sec
ldi counter_sec_t, 0
rjmp return_sec

;наращивание секунд
before_sec:
cpi counter_sec_t, 9
brne plus_one_sec
ldi counter_sec_t, 0
rjmp return_sec
plus_one_sec:
inc counter_sec_t
rjmp return_sec

;возврат из прерывания
return_sec:

ldi tmp2, 0x80
eor mask, tmp2

pop tmp
sts SREG, tmp
pop tmp2
pop tmp
reti


;прерывание на добавление минут
add_min:
push tmp
push tmp2
lds tmp,SREG
push tmp

sbis PINC, PC0
call CLEAR_TIMER


sbis PINC, PC1
jmp START_MIN
jmp return_min

START_MIN:
;проверка, не достигли ли минуты предельного значения
cpi counter_min_t, 6
brne after_checking_end
cpi counter_min_u, 0
brne after_checking_end
clr tmp
out TCCR0, tmp
rjmp end
after_checking_end:

;наращивание минут
cpi counter_min_u, 9
brne plus_one_min
inc counter_min_t
ldi counter_min_u, 0
rjmp return_min
plus_one_min:
inc counter_min_u

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
brne dc
ldi tmp, 0xEF
rjmp exit

dc:
ldi tmp, 0x39

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

CLEAR_TIMER:
	;зануление регистров для счёта времени
	ldi counter_sec_u, 12
	ldi counter_sec_t, 0
	ldi counter_min_u, 0
	ldi counter_min_t, 0
	ret
