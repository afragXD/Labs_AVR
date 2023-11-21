.include "m128def.inc"
.device ATmega128
.def Temp = R16 ; временный регистр
.def Temp2 = R29 ; временный регистр
.def Test = R17 ; временный тестовый регистр
.def TCount = R18 ; задержка
.equ Const8 = 3
.equ ConstSec = 10
.equ Const61Sec = 61
;***** Инициализация
RESET:
jmp Start
.org $0020
jmp T0_ovf

;начало обработчика прерывания по переполнению таймера-счетчика
T0_ovf: 
push Temp
push Test
; установить начальное значение TCNT0
Ldi Temp, 12
Out TCNT0, Temp

metka2:
cpi Tcount, Const8
brlo cont
; каждый 3-й импульс
clr Tcount
in Temp, PortA ; опрос состояния LED

sbis PIND,PD0 ; кнопка SW0 нажата? Если да, то ниже:
	call ON_SW0

sbis PIND,PD1 ; кнопка SW1 нажата? Если да, то ниже:
	call ON_SW1

in Test, PIND ;прочитать PORTD
com Test ;проверить переключатели
brne outled ;SW0 или SW1 нажаты?
; SW0 & SW1 отжаты /LED-светодиоды выключены
outled: 
	out PORTA,Temp ;вывод данных в PORTB
	out PORTB,Temp2
cont: 
	inc Tcount
	pop Test
	pop Temp
	reti
; конец обработчика. Начало кода инициализации
Start:
; инициализация указателя стека
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, low(RAMEND)
out SPL, temp
clr Tcount
; инициализация регистров портов ввода-вывода
clr Temp
out DDRD, Temp
ser temp
out PORTD, Temp
ser Temp
out DDRB, Temp
out PORTB, Temp
out DDRA, Temp
out PORTA, Temp
; Установка начального значения регистра TCNT0
Ldi Temp, 12
out TCNT0, Temp
ldi Temp, (0<<FOC0)+(0<<COM01)+(0<<COM00)+(0<<WGM01)+(0<<WGM00)+(1<<CS02) +(1<<CS01)+(1<<CS00); f/1024 (f частота тактов МК)
out TCCR0, Temp ; в результате таймер-счетчик 0 настроен в 
; нормальный режим счета и тут же начинает считать!!!!
; Предварительная очистка возможного запроса прерывания 
in temp, TIFR
ori temp, (1<<TOV0)
out TIFR, temp
; Разрешение запроса прерывания по переполнению 
ldi temp, (1<<TOIE0)
out TIMSK, temp
sei; Глобальное разрешение любых прерываний
	ser temp ; temp = FF
	ser temp2
loop: rjmp loop ; бесконечный цикл

ON_SW1:
	com Temp; инвертировать Temp
	inc Temp ;инкремент переменной Temp
	cpi Temp, ConstSec ; сравнить Temp и ConstSec(10)
	brlo IF_SEC ; если != то прыгнуть к IF_SEC иначе дальше
	
	;действия при достижении 1 секунды
	;сбросить Temp(десятые секунды) и инкремент temp2(секунды)
	ser Temp
	com temp2
	inc temp2

	;сравнение с 61 секундой
	cpi temp2, Const61Sec
	brlo IF_61_SEC
	ser temp
	ser temp2
	ret

IF_SEC:
	
	com Temp ; инвертировать Temp
	ret

IF_61_SEC:
	com temp2 ; инвертировать temp2
	ret

ON_SW0:
	ser Temp ; Temp=FF
	ser Temp2
	ret