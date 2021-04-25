#make_bin#

; BIN is plain binary format similar to .com format, but not limited to 1 segment;
; All values between # are directives, these values are saved into a separate .binf file.
; Before loading .bin file emulator reads .binf file with the same file name.

; All directives are optional, if you don't need them, delete them.

; set loading address, .bin file will be loaded to this address:
#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

; set entry point:
#CS=0000h#    ; same as loading segment
#IP=0000h#    ; same as loading offset

; set segment registers
#DS=0000h#    ; same as loading segment
#ES=0000h#    ; same as loading segment

; set stack
#SS=0000h#    ; same as loading segment
#SP=FFFEh#    ; set to top of loading segment

; set general registers (optional)
#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

jmp    st1
nop

db    1024 dup(0)
; Main program

st1:    cli
; intialize ds,es,ss to start of RAM
mov    ax,0200h
mov    ds,ax
mov    es,ax
mov    ss,ax
mov    sp,0FFFEH
mov si,0000


; DATA
JMP START
PORTA1 EQU    00h
PORTB1 EQU    02h
PORTC1 EQU    04h
CREG1  EQU    06h
PORTA2 EQU  08h
PORTB2 EQU  0ah
PORTC2 EQU  0ch
CREG2  EQU  0eh
CNT0   EQU  10H
CREG3  EQU  16H
STEPPER_MOTOR EQU 88H

PERKC DB 100
FIVEC DB 100
DMC   DB 100

PERKID EQU 36
FIVEID EQU 61
DMID   EQU 86
PRICE  DB  ?





START:
; Initialize 8255A
; portA1 as input, portB1 is NC, portC1 lower as output and portc1 upper as input.

MOV    AL, 9AH ;10011010b
OUT    CREG1, AL
; portA2 as output, portB2 as output, portC2 lower as output and portc2 upper as input
MOV AL, 88H ;10001000b
OUT CREG2, AL

; initialise all ouput as 0
MOV AL,00
OUT PORTC1,AL
MOV AL,00H
OUT PORTA2,AL
MOV AL,00H
OUT PORTB2,AL



Main:

;first making sure that all keys are released
x1 : IN AL,PORTC2
CMP AL,70H
JNZ X1

;checking for a key press
x2:  IN AL,PORTC2
AND AL,70H
CMP AL,60H
JZ  PERK
CMP AL,50H
JZ  FIVESTAR
CMP AL,30H
JZ  DM
JMP X2  ; loop back if no button pressed

PERK:

; checking count of available Perk chocolates
CMP PERKC,0
JZ LED_GLOW_PERK

; if available then process starts
CALL ACCEPT_COIN
MOV PRICE,PERKID
CALL PRICE_INITIATE
CALL DELAY_20MS
CALL DISPENSE_PERK
CALL DELAY_20MS
DEC PERKC
CALL CLOSE_COIN
JMP START


FIVESTAR:

; checking count of available Five Star chocolates
CMP FIVEC,0
JZ LED_GLOW_FIVE

; if available then process starts
CALL ACCEPT_COIN
MOV PRICE,FIVEID
CALL PRICE_INITIATE
CALL DISPENSE_FIVE
DEC FIVEC
CALL CLOSE_COIN
JMP START


DM:

; checking count of available Dairy Milk chocolates
CMP DMC,0
JZ LED_GLOW_DM

; if available then process starts
CALL ACCEPT_COIN
MOV PRICE,DMID
CALL PRICE_INITIATE
CALL DISPENSE_DM
DEC DMC
CALL CLOSE_COIN
JMP START


LED_GLOW_PERK:
; to glow LED red indicating no Perk chocolate available
;PC0 IS HIGH FOR PERK
MOV AL,01H
OUT PORTC2,AL


LED_GLOW_FIVE:
; to glow LED red indicating no Five Star chocolate available
;PC1 IS HIGH FOR FIVESTAR
MOV AL,02H ;00000010B
OUT PORTC2,AL


LED_GLOW_DM:
; to glow LED red indicating no Dairy Milk chocolate available
;PC2 IS HIGH FOR DAIRYMILK
MOV AL,04H ;00000100B
OUT PORTC2,AL


hlt


ACCEPT_COIN PROC NEAR
; moves the stepper motor-4 to open the coin aceptance flap
PUSHF
PUSH AX
PUSH BX
PUSH CX

MOV AL,STEPPER_MOTOR
MOV CX,50      ; 50 is equivalent to 180 Deg rotation

ROT_MOTOR_4_CLKWISE: ; rotates the motor clockwise
MOV     BL,AL
AND     AL,0F0H
OUT     PORTB2,AL
CALL    DELAY_20MS
MOV     AL,BL
ROR     AL,01
DEC     CX
JNZ     ROT_MOTOR_4_CLKWISE

; shut off motor
MOV AL,00H
OUT PORTB2,AL

POP CX
POP BX
POP AX
POPF
RET
ACCEPT_COIN ENDP


PRICE_INITIATE PROC NEAR
; takes ADC input and waits until it becomes equal to required coin weight
PUSHF
PUSH AX
PUSH BX
PUSH CX

mov cl,PRICE

;ale activated
X8:
mov AL,01H ;00000001B
OUT PORTC1,AL

;soc high
mov AL,03H ;00000011B
OUT PORTC1,AL

; waiting
nop
nop
nop
nop

;ale low
and AL,11111110b
OUT PORTC1,AL
;soc low
and AL,11111101b
OUT PORTC1,AL

X7: ; checking for EOC high
IN AL,PORTC1
AND AL,10H
JZ X7

; OE high
MOV AL,04H
OUT PORTC1,AL

; taking ADC input
IN AL,PORTA1
CMP AL,CL   ; comparing to pre-defined coin weight required for the selected chocolate
JNZ X8  ; looping back to take another input from ADC if weight not matched

POP CX
POP BX
POP AX
POPF
RET
PRICE_INITIATE ENDP


DISPENSE_PERK PROC NEAR
; rotates the motor-1 to dispense Perk Chocolate
PUSHF
PUSH AX
PUSH BX
PUSH CX

MOV AL,STEPPER_MOTOR
MOV CX,100      ;100 IS EQUIVALENT TO 360 DEG ROTATION
ROT_MOTOR_1: MOV     BL,AL
AND     AL,0FH
OUT     PORTA2,AL
CALL    DELAY_20MS
MOV     AL,BL
ROL     AL,01
DEC     CX
JNZ     ROT_MOTOR_1

MOV AL,00
OUT PORTA2,AL

POP CX
POP BX
POP AX
POPF
RET
DISPENSE_PERK ENDP


DISPENSE_FIVE PROC NEAR
; rotates the motor-2 to dispense Five Star Chocolate
PUSHF
PUSH AX
PUSH BX
PUSH CX

MOV AL,STEPPER_MOTOR
MOV CX,100      ;100 IS EQUIVALENT TO 360 DEG ROTATION

ROT_MOTOR_2: MOV     BL,AL
AND     AL,0F0H
OUT     PORTA2,AL
CALL    DELAY_20MS
MOV     AL,BL
ROL     AL,01
DEC     CX
JNZ     ROT_MOTOR_2

MOV     AL,00
OUT     PORTA2,AL

POP CX
POP BX
POP AX
POPF
RET
DISPENSE_FIVE ENDP


DISPENSE_DM PROC NEAR
; rotates the motor-3 to dispense Dairy Milk Chocolate
PUSHF
PUSH AX
PUSH BX
PUSH CX

MOV AL,STEPPER_MOTOR
MOV CX,100      ;100 IS EQUIVALENT TO 360 DEG ROTATION

ROT_MOTOR_3: MOV     BL,AL
AND     AL,0FH
OUT     PORTB2,AL
CALL    DELAY_20MS
MOV     AL,BL
ROL     AL,01
DEC     CX
JNZ     ROT_MOTOR_3

MOV     AL,00
OUT     PORTB2,AL

POP CX
POP BX
POP AX
POPF
RET
DISPENSE_DM ENDP


CLOSE_COIN PROC NEAR
; moves the stepper motor-4 to close the coin aceptance flap
PUSHF
PUSH AX
PUSH BX
PUSH CX

MOV AL,STEPPER_MOTOR
MOV CX,50      ;50 IS EQUIVALENT TO 180 DEG ROTATION

ROT_MOTOR_4_ANTICLKWISE: MOV     BL,AL
AND     AL,0F0H
OUT     PORTB2,AL
CALL    DELAY_20MS
MOV     AL,BL
ROL     AL,01
DEC     CX
JNZ     ROT_MOTOR_4_ANTICLKWISE

MOV AL,00
OUT PORTB2,AL

POP CX
POP BX
POP AX
POPF
RET
CLOSE_COIN ENDP


DELAY_20MS PROC NEAR
; general delay function
PUSHF
PUSH AX
PUSH BX
PUSH CX
PUSH DX

NOP
NOP
NOP
NOP
NOP
NOP

POP DX
POP CX
POP BX
POP AX
POPF
RET
DELAY_20MS ENDP