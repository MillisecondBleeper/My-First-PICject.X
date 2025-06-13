PROCESSOR 16F15223
//********* Auto Generated **********
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
//********* End Auto Generated **********	
#include <xc.inc>
#define PWM_LOWER_LIMIT 170
#define PWM_OFFSET_LIMIT 213
PSECT reset_vec,class=CODE,delta=2
reset_vec: //init on all retest
	PAGESEL(init) 
	goto init
PSECT intentry,class=CODE,delta=2
int_vec: //interrupt vector
	BANKSEL(PIR0)
	btfsc ADIF //we only use A/D interrupt, but this can handle selecting interrupts to process.
	call handle_adif
int_ret:
	retfie
handle_adif:
	bcf ADIF		//clear interrupt flag. Required.
	call setupret		//puts minimum value into the reth:retl pair
	call merge_adc_ret_lim	//adds value from potentiometer which is limited
	incf adtoggle		//limits the output update rate for PWM3 to 1/4 of the true PWM frequency
	movf adtoggle, w
	andlw 0xFC
	btfsc ZERO
	bra no_pwm3		//\_
	clrf adtoggle 
	BANKSEL(PWM3DCL)	//output to PWM3
	movf reth, w
	movwf PWM3DCH
	movf retl, w
	movwf PWM3DCL 
	bra handle_adif_return
no_pwm3:
	BANKSEL(PWM3DCL)	//0% duty cycle = hold low
	clrf PWM3DCH
	clrf PWM3DCL
handle_adif_return:
	BANKSEL(PWM4DCL)
	movf reth, w		//output to PWM4
	movwf PWM4DCH
	movf retl, w
	movwf PWM4DCL
	return
	
	
setupret: //this puts the limit into the register pair as left-aligned 10-bit value
	movlw (PWM_LOWER_LIMIT >> 2) & 0xFF
	movwf reth
	movlw ( PWM_LOWER_LIMIT & 0x03 ) << 6
	movwf retl
	return

merge_adc_ret_lim: //this adds the ADC result to the return value
	BANKSEL(ADRESH)
	movf ADRESH, w
	movwf b_reg
	movlw PWM_OFFSET_LIMIT	//limit
	subwf b_reg, w
	btfss CARRY
	bra merge_adc_ret_lim_not
	movlw PWM_OFFSET_LIMIT
	movwf b_reg
merge_adc_ret_lim_not:	//left-align the value as 10-bit
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
	BANKSEL(RC3PPS) //setup C3 and C4 to output PWM3 and PWM4
	movlw 0x03
	movwf RC3PPS
	movlw 0x04
	movwf RC4PPS
	BANKSEL(TRISC) //Tri-state / output disable
	bcf TRISC3
	bcf TRISC4
	BANKSEL(ANSELC) //analog select / digital input disable
	bcf ANSC3
	bcf ANSC4
	movlw 0
	addlw 1
	bra -2 //loop with counter (spin and demonstrate execution)
pwm_setup:	//setup PWM per PIC16F15223 datasheet directions. 
		//see Microchip doc DS40002195D 
	BANKSEL(PWM3CON)
	clrf BANKMASK(PWM3CON)
	clrf BANKMASK(PWM4CON)
	BANKSEL(T2PR)
	movlw 0xFF		//period = 256
	movwf T2PR
	BANKSEL(PWM3DCH)
	movlw 0x80		//initialize to 50% Duty Cycle
	movwf BANKMASK(PWM3DCH)
	clrf BANKMASK(PWM3DCL)
	movwf BANKMASK(PWM4DCH)
	clrf BANKMASK(PWM4DCL)
	BANKSEL(PIR1)
	bcf TMR2IF
	BANKSEL(T2PR)
	movlw 0b001		//clk src = Fosc/4 -- required for PWM
	movwf T2CLKCON
	movlw 0b00000000	//free-running, hw reset is not used
	movwf T2HLT
	movlw 0b11110000	//T2 ON, prescale=1/128, postscale=1
	movwf T2CON
	BANKSEL(PWM3CON)	//enable PWM outputs
	bsf PWM3EN
	bsf PWM4EN
	return
adc_setup:
	BANKSEL(TRISC)		//tristate and setup for analog input
	bsf TRISC2
	BANKSEL(ANSELC)
	bsf ANSC2
	BANKSEL(ADCON0)		//AD source = C2, V+=Vdd, convert on T2,clk=Fosc/64
	movlw 0b01001001
	movwf ADCON0
	movlw 0b01100000
	movwf ADCON1
	movlw 0b00000100
	movwf ADACT
	BANKSEL(PIR0)		//enable AD interrupt
	bsf ADIE
	bsf PEIE
	bsf GIE
	return
PSECT end_init,class=CODE,delta=2
PSECT powerup	//required to compile, not used.
PSECT cinit	//""
PSECT functab	//""
PSECT udata_shr //16 bytes: 0x70-0x7F is accessible in all banks
reth:	//2-byte return value, used as 10-bit left-justified
	DS 1
retl:
	DS 1
adtoggle://used to divide down effective PWM period
	DS 1
b_reg:	//used for 2-bute manipulation and temp storage
	DS 1

	
//4x14bit ID; here used as 8x7bit ascii. Currently "hellorld"
//recursive macros not supported.
#define PACK_ASCII_7_BITS_4(a, b, args...) ( ((a) << 7) | (b) ), PACK_ASCII_7_BITS_3(args)
#define PACK_ASCII_7_BITS_3(a, b, args...) ( ((a) << 7) | (b) ), PACK_ASCII_7_BITS_2(args)
#define PACK_ASCII_7_BITS_2(a, b, args...) ( ((a) << 7) | (b) ), PACK_ASCII_7_BITS_1(args)
#define PACK_ASCII_7_BITS_1(a, b, args...) ( ((a) << 7) | (b) )
PSECT userid,class=IDLOC,delta=2,noexec,global
 userid:
	DW PACK_ASCII_7_BITS_4('H', 'e', 'l', 'l', 'o', 'r', 'l', 'd')

END


