PROCESSOR 16F15223
// PIC16F15223 Configuration Bit Settings
// CONFIG1
CONFIG FEXTOSC = OFF    // External Oscillator Mode Selection bits (Oscillator not enabled)
CONFIG RSTOSC = HFINTOSC_32MHZ// Power-up Default Value for COSC bits (HFINTOSC (32 MHz))
CONFIG CLKOUTEN = OFF   // Clock Out Enable bit (CLKOUT function is disabled; I/O function on RA4)
CONFIG VDDAR = LO       // VDD Range Analog Calibration Selection bit (Internal analog systems are calibrated for operation between VDD = 1.8V - 3.6V)

// CONFIG2
CONFIG MCLRE = EXTMCLR  // Master Clear Enable bit (If LVP = 0, MCLR pin is MCLR; If LVP = 1, RA3 pin function is MCLR)
CONFIG PWRTS = PWRT_OFF // Power-up Timer Selection bits (PWRT is disabled)
CONFIG WDTE = OFF       // WDT Operating Mode bits (WDT disabled; SEN is ignored)
CONFIG BOREN = ON       // Brown-out Reset Enable bits (Brown-out Reset Enabled, SBOREN bit is ignored)
CONFIG BORV = LO        // Brown-out Reset Voltage Selection bit (Brown-out Reset Voltage (VBOR) set to 1.9V)
CONFIG PPS1WAY = ON     // PPSLOCKED One-Way Set Enable bit (The PPSLOCKED bit can be set once after an unlocking sequence is executed; once PPSLOCKED is set, all future changes to PPS registers are prevented)
CONFIG STVREN = OFF     // Stack Overflow/Underflow Reset Enable bit (Stack Overflow or Underflow will not cause a reset)

// CONFIG3

// CONFIG4
CONFIG BBSIZE = BB512   // Boot Block Size Selection bits (512 words boot block size)
CONFIG BBEN = OFF       // Boot Block Enable bit (Boot Block is disabled)
CONFIG SAFEN = OFF      // SAF Enable bit (SAF is disabled)
CONFIG WRTAPP = OFF     // Application Block Write Protection bit (Application Block is not write-protected)
CONFIG WRTB = OFF       // Boot Block Write Protection bit (Boot Block is not write-protected)
CONFIG WRTC = OFF       // Configuration Registers Write Protection bit (Configuration Registers are not write-protected)
CONFIG WRTSAF = OFF     // Storage Area Flash (SAF) Write Protection bit (SAF is not write-protected)
CONFIG LVP = ON         // Low Voltage Programming Enable bit (Low Voltage programming enabled. MCLR/Vpp pin function is MCLR. MCLRE Configuration bit is ignored.)

// CONFIG5
CONFIG CP = OFF         // User Program Flash Memory Code Protection bit (User Program Flash Memory code protection is disabled)	
#include <xc.inc>
	
PSECT reset_vec,class=CODE,delta=2
reset_vec: 
	PAGESEL(init) 
	goto init
PSECT intentry,class=CODE,delta=2
int_vec:
	BANKSEL(PIR0)
	btfsc ADIF
	call handle_adif
int_ret:
	retfie
handle_adif:
	bcf ADIF
	call setupret
	call merge_adc_ret_250
	incf adtoggle
	movf adtoggle, w
	andlw 0xFC
	btfsc ZERO
	bra no_pwm3
	clrf adtoggle 
	BANKSEL(PWM3DCL)
	movf reth, w
	movwf PWM3DCH
	movf retl, w
	movwf PWM3DCL
	bra handle_adif_return
no_pwm3:
	BANKSEL(PWM3DCL)
	clrf PWM3DCH
	clrf PWM3DCL
handle_adif_return:
	movf reth, w
	movwf PWM4DCH
	movf retl, w
	movwf PWM4DCL
	return
setupret:
	movlw 170>>2
	movwf reth
	movlw ( 170& 0x03 ) << 6
	movwf retl
	return

merge_adc_ret_250:
	BANKSEL(ADRESH)
	movf ADRESH, w
	movwf b_reg
	movlw 213
	subwf b_reg, w
	btfss CARRY
	bra merge_adc_ret_250_not
	movlw 213
	movwf b_reg
merge_adc_ret_250_not:
	clrw
	bcf CARRY
	rrf b_reg
	rrf WREG
	addwf retl, f
	movf b_reg, w
	addwfc reth, f
	return

	
	
	


PSECT init,class=CODE,delta=2
 init:
	call pwm_setup
	call adc_setup
	BANKSEL(RC3PPS)
	movlw 0x03
	movwf RC3PPS
	movlw 0x04
	movwf RC4PPS
	BANKSEL(TRISC)
	bcf TRISC3
	bcf TRISC4
	BANKSEL(ANSELC)
	bcf ANSC3
	bcf ANSC4
	movlw 0
	addlw 1
	bra -2
pwm_setup:
	BANKSEL(PWM3CON)
	clrf BANKMASK(PWM3CON)
	clrf BANKMASK(PWM4CON)
	BANKSEL(T2PR)
	movlw 0xFF
	movwf T2PR
	BANKSEL(PWM3DCH)
	movlw 0x80
	movwf BANKMASK(PWM3DCH)
	clrf BANKMASK(PWM3DCL)
	movwf BANKMASK(PWM4DCH)
	clrf BANKMASK(PWM4DCL)
	BANKSEL(PIR1)
	bcf TMR2IF
	BANKSEL(T2PR)
	movlw 0b001
	movwf T2CLKCON
	movlw 0b10000100
	movwf T2HLT
	movlw 0b11110000
	movwf T2CON
	BANKSEL(PWM3CON)
	bsf PWM3EN
	bsf PWM4EN
	return
adc_setup:
	BANKSEL(TRISC)
	bsf TRISC2
	BANKSEL(ANSELC)
	bsf ANSC2
	BANKSEL(ADCON0)
	movlw 0b01001001
	movwf ADCON0
	movlw 0b01100000
	movwf ADCON1
	movlw 0b00000100
	movwf ADACT
	BANKSEL(PIR0)
	bsf ADIE
	bsf PEIE
	bsf GIE
	return
PSECT end_init,class=CODE,delta=2
PSECT powerup
PSECT cinit
PSECT functab
PSECT udata_shr
reth:
	DS 1
retl:
	DS 1
adtoggle:
	DS 1
b_reg:
	DS 1

	
	
#define PACK_ASCII_7_BITS_4(a, b, args...) ( ((a) << 7) | (b) ), PACK_ASCII_7_BITS_3(args)
#define PACK_ASCII_7_BITS_3(a, b, args...) ( ((a) << 7) | (b) ), PACK_ASCII_7_BITS_2(args)
#define PACK_ASCII_7_BITS_2(a, b, args...) ( ((a) << 7) | (b) ), PACK_ASCII_7_BITS_1(args)
#define PACK_ASCII_7_BITS_1(a, b, args...) ( ((a) << 7) | (b) )
PSECT userid,class=IDLOC,delta=2,noexec,global
 userid:
	DW PACK_ASCII_7_BITS_4('H', 'e', 'l', 'l', 'o', 'r', 'l', 'd')

END


