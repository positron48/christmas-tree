.include "tn24Adef.inc"
;= Start macro.inc ========================================
 .def Rmode = R16
 .def Rleft = R17
 .def Rright = R18
 .def Rtime = R19
 .def Rtemp = R20
 .def Ri = R21 
;= End macro.inc  ========================================
; RAM =====================================================
		.DSEG			; Сегмент ОЗУ
; FLASH ===================================================
		.CSEG			; Кодовый сегмент
		.org 0
		//вектор прерываний
		rjmp RESET
		rjmp INT0
		rjmp PCINT0_
		rjmp PCINT1_
		rjmp WDT
		rjmp TIM1_CAPT
		rjmp TIM1_COMPA
		rjmp TIM1_COMPB
		rjmp TIM1_OVF
		rjmp TIM0_COMPA
		rjmp TIM0_COMPB
		rjmp TIM0_OVF
		rjmp ANA_COMP
		rjmp ADC_
		rjmp EE_RDY
		rjmp USI_STR
		rjmp USI_OVF

;RESET:		// External Pin, Power-on Reset, Brown-out Reset, Watchdog Reset
INT0_:		// External Interrupt Request 0
PCINT0_:		// Pin Change Interrupt Request 0
;PCINT1_:		// Pin Change Interrupt Request 1
WDT:		// Watchdog Time-out
TIM1_CAPT:	// Timer/Counter1 Capture Event
;TIM1_COMPA:	// Timer/Counter1 Compare Match A
TIM1_COMPB:	// Timer/Counter1 Compare Match B
TIM1_OVF:	// Timer/Counter1 Overflow
TIM0_COMPA:	// Timer/Counter0 Compare Match A
TIM0_COMPB:	// Timer/Counter0 Compare Match B
TIM0_OVF:	// Timer/Counter0 Overflow
ANA_COMP:	// Analog Comparator
ADC_:		// ADC Conversion Complete
EE_RDY:		// EEPROM Ready
USI_STR:	// USI START
USI_OVF:	// USI Overflow
		reti
	
RESET:
		ldi Rtemp, 0b11100000
		out DDRA, Rtemp

		ldi Rtemp, 0b00000100
		out DDRB, Rtemp

		ldi Rmode, 0
		ldi Rleft, 0
		ldi Rright, 2
		ldi Rtime, 0x01

		//разрешаем прерывание PCIF1
		ldi Rtemp, 0b00100000
		out GIMSK,Rtemp            
		//только для ноги PCINT8
		ldi Rtemp, 0b00000001
		out PCMSK1,Rtemp

		ldi Rtemp,0b00100010   ;разрешить прерывание компаратора
		out TIMSK1,Rtemp

		ldi Rtemp,0b00000010   ;тактовый сигнал = CK/8
		out TCCR1B,Rtemp

		out OCR1AH,Rtime		;инициализация компаратора
		ldi Rtemp,0x00 
		out OCR1AL,Rtemp

		ldi Rtemp,0            ;обнуление таймера
		out TCNT1H,Rtemp
		out TCNT1L,Rtemp
		
		sei
body:
		rjmp body

TIM1_COMPA:
		ldi Rtemp,0            ;обнуление таймера
		out TCNT1H,Rtemp
		out TCNT1L,Rtemp

		cp Ri,Rright          ;сравнить с крайним знач.
		breq Init             ;если равно - загрузка нач. знач.

ReadArray:
		ldi ZH,High(Array*2)  ;загрузка начального адреса массива
		ldi ZL,Low(Array*2)

		ldi Rtemp,0            ;прибавление внутр. адреса
		add ZL,Ri
		adc ZH,Rtemp

		lpm                   ;загрузка из ПЗУ

		mov Rtemp,R0           ;копирование в РОН
		inc Ri             ;увеличение внутр. адреса

		out PortA, Rtemp       ;вывод в порт A

		ldi ZH,High(Array*2)  ;загрузка начального адреса массива
		ldi ZL,Low(Array*2)

		ldi Rtemp,0            ;прибавление внутр. адреса
		add ZL,Ri
		adc ZH,Rtemp

		lpm                   ;загрузка из ПЗУ

		mov Rtemp,R0           ;копирование в РОН
		inc Ri             ;увеличение внутр. адреса

		out PortB, Rtemp       ;вывод в порт B
		reti

Init:    
		mov Ri,Rleft          ;загрузить нач. значение
		rjmp ReadArray

PCINT1_:
		//проверяем состояние ноги
		//т.к. прерывание от 1 ноги, достаточно проверить уровень
		//если 0 - прерывание по спаду
		//нет фикса дребезга
		sbic PINB, 0
		reti

		inc Rmode
		cpi Rmode, 1
		breq mode1

		cpi Rmode, 2
		breq mode2

		cpi Rmode, 3
		breq mode3

		cpi Rmode, 4
		breq mode4

		cpi Rmode, 5
		breq mode0

		reti

mode0:
		ldi Rmode, 0
		ldi Rleft, 0
		ldi Rright, 2
		ldi Ri, 2
		ldi Rtime, 0x2f
		rjmp init_compare
mode1:
		ldi Rleft, 2
		ldi Rright, 6
		ldi Ri, 6
		ldi Rtime, 0xfa
		rjmp init_compare
mode2:
		ldi Rleft, 6
		ldi Rright, 12
		ldi Ri, 12
		ldi Rtime, 0x50
		rjmp init_compare
mode3:
		ldi Rleft, 12
		ldi Rright, 48
		ldi Ri, 48
		ldi Rtime, 0x10
		rjmp init_compare
mode4:
		ldi Rleft, 48
		ldi Rright, 54
		ldi Ri, 54
		ldi Rtime, 0x50
init_compare:
		out OCR1AH,Rtime		;инициализация компаратора
		ldi Rtemp,0x00 
		out OCR1AL,Rtemp

		ldi Rtemp,0            ;обнуление таймера
		out TCNT1H,Rtemp
		out TCNT1L,Rtemp
		reti

Array:
		.db   0b11100000,0b00000100//mode0
		.db   0b11100000,0b00000100//mode1
		.db   0b00000000,0b00000000
		.db   0b10000000,0b00000100//mode2
		.db   0b11000000,0b00000000
		.db   0b10100000,0b00000000
		.db   0b00000000,0b00000000//mode3
		.db   0b10000000,0b00000100
		.db   0b00000000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b10000000,0b00000100
		.db   0b00000000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b11000000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b11000000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b10100000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b10100000,0b00000000
		.db   0b00000000,0b00000000
		.db   0b10100000,0b00000000//mode4 - reverce mode2
		.db   0b11000000,0b00000000
		.db   0b10000000,0b00000100


; EEPROM ==================================================
		.ESEG			; Сегмент EEPROM