;**********************************************************************
;
; Tom Pittman's 6502 Tiny Basic
;
; <<Tom... put a copyright message here!>>>
;
; Disassembly provided by Dwight Elvey (.wordight.elvey@amd.com) after
; I put out a request on the cctech mailing list.  Dwight seems to be
; the only person who kept a functional copy of 6502 TB!
;
; Re-constructed source by Bob Applegate (bob@applegate.org).  Most of
; the comments are from my perspective, so references to "me" or "I"
; refer to Bob.
;
;**********************************************************************
;
; Began reconstruction of the source code 06/07/2004 for the TASM
; cross assembler.  Converted to AS65 format 05/04/2016 (May the Fourth
; be with you!).
;
; Some of the comments were taken directly from the original
; Tiny Basic User Manual and/or the C version of the code that
; Tom posted in May 2004 to his website.  Others were my
; personal additions.  Comments might be wrong!  If you find an
; error, please fix it, expand the explanation, etc, and then
; send updates to at least Tom.  I'd appreciate them also.
;
;**********************************************************************
;
; These are used to control the target environment.  You must define
; exactly one of these options or else you won't get what you want.
; 
; The GENERIC option builds a generic 6502 TB located at $2000.  You'll
; need to manually poke in your I/O routines.
;
; The KIM1 option builds for the KIM with the code located at $0200.
; It also builds a KIM-specific I/O function at address $0100.
;
false	=	0
true	=	~false
;
;
;**********************************************************************
;
; ASCII Constants
;
CTRL_A	=	$01
CTRL_B	=	$02
CTRL_C	=	$03
CTRL_D	=	$04
CTRL_E	=	$05
CTRL_F	=	$06
CTRL_G	=	$07
CTRL_H	=	$08
CTRL_I	=	$09
CTRL_J	=	$0a
CTRL_K	=	$0b
CTRL_L	=	$0c
CTRL_M	=	$0d
CTRL_N	=	$0e
CTRL_O	=	$0f
CTRL_P	=	$10
CTRL_Q	=	$11
CTRL_R	=	$12
CTRL_S	=	$13
CTRL_T	=	$14
CTRL_U	=	$15
CTRL_V	=	$16
CTRL_W	=	$17
CTRL_X	=	$18
CTRL_Y	=	$19
CTRL_Z	=	$1a
;
; More common names for common ASCII symbols
;
NUL	=	$00
BELL	=	$07
BS	=	$08
LF	=	$0a
CR	=	$0d
DEL	=	$7f
;
;**********************************************************************
; These are (some of) the IL opcodes.  See Tom's C code or the Tiny
; Basic Experimenter's book if you want to learn what they're about.
;
SX	=	$00
SX0	=	$00
SX1	=	$01
SX2	=	$02
SX3	=	$03
SX4	=	$04
SX5	=	$05
SX6	=	$06
SX7	=	$07
NO	=	$08	;No-op
LB	=	$09
LN	=	$0a
DS	=	$0b
SP	=	$0c
SB	=	$10
RB	=	$11
FV	=	$12
SV	=	$13
GS	=	$14
RS	=	$15
GO	=	$16
NE	=	$17
AD	=	$18
SU	=	$19
MP	=	$1a
DV	=	$1b
CP	=	$1c
NX	=	$1d
LS	=	$1f
PN	=	$20
PQ	=	$21
PT	=	$22
NL	=	$23
PC	=	$24
GL	=	$27
IL	=	$2a
MT	=	$2b
XQ	=	$2c
WS	=	$2d
US	=	$2e
RT	=	$2f
BR	=	$40

;
;**********************************************************************
; Zero page storage.  Tom seems to be fairly consistant between all of
; the versions of TB, so I used the 1802 and C versions to get names
; and figure out what these variables do.  There are some bits of
; comments in here from what I discovered, what Tom documented, etc.
;
; The lower bound is stored in locations 0020-0021 and the
; upper bound is in locations 0022-0023.
;
;0020-0021       Lowest address of user program space
;0022-0023       Highest address of program space
;0024-0025       Program end + stack reserve
;0026-0027       Top of GOSUB stack
;0028-002F       Interpreter parameters
;0030-007F       Input line buffer & Computation stack
;0080-0081       Random Number Generator workspace
;00B6-00C7       Interpreter temporaries
;00B8            Start of User program (PROTO)
;
;		.org	$20
;UserProg	ds	2	;Start of user program area
;EndUser		ds	2	;End of user program/stack
;EndProg		ds	2	;End of Basic program
;GoStkTop	ds	2	;Top of Gosub stack
;LineNumber	ds	2	;Current Basic line number
;IlPtr		ds	2	;pointer to current IL statement
;LinePtr		ds	2	;pointer to/in current user statement
;Source		ds	2	;source pointer for memory moves

UserProg	=	$20	;Start of user program area
EndUser		=	$22	;End of user program/stack
EndProg		=	$24	;End of Basic program
GoStkTop	=	$26	;Top of Gosub stack
LineNumber	=	$28	;Current Basic line number
IlPtr		=	$2A	;pointer to current IL statement
LinePtr		=	$2C	;pointer to/in current user statement
Source		=	$2E	;source pointer for memory moves


;
; 0030-007F       Input line buffer & Computation stack
;
EXPRESS_STACK_SIZE	=	$30
ExpressStack		=	$50
ExpressStackTop		=	ExpressStack + EXPRESS_STACK_SIZE-1
;
; 0080-0081       Random Number Generator workspace
;
RandNum			=	$80
;
; Variables are pretty simple.  The ASCII character (A-Z)
; is multiplied by two, giving an address in page zero which
; contains the data.  Because of this, you can't just arbitrarily
; move the Variables array to someplace else in memory.
;
; 0082-0083       Variable "A"
; 0084-0085       Variable "B"
; ...             ...
; 00B4-00B5       Variable "Z"
;
Variables		=	$82

Temp2			=	$B6	;$b6 - Another 16 bit temp
Dest			=	$B8	;destination for memory moves
UNK1			=	$BA	;$ba - ???
Temp1			=	$BC	;$bc temp 16 bit value for many routines
;
; If this is non-zero, then we're currently running a BASIC program.
;
Running			=	$BE
;
; This is the count of the number of characters on the current output
; line.  Also used to count characters on user input.
;
CharCount		=	$BF
;
; $C1/$C2 = expression stack pointer
; $C0     = bottom of expression stack
;

ExStackBottm		=	$C0
ExStackPtr		=	$C1
pp_temp			=	$C3	;another temp for peek/poke
UNK2			=	$C5
GosubStkPtr		=	$C7	;Gosub stack pointer
;
;**********************************************************************
;

		.org	$1000

; This is the cold-start entry point.  This should be the first
; bit of code executed when TB is started.
;
COLD		jmp	ColdEntry
;
; This is the warm-start entry point.
;
WARM		jmp	WarmEntry
;
; Subroutine INCHAR is a jmp to a subroutine to read one ASCII
; character from the console/terminal.  Subroutine OUTCHAR is a jmp to a
; subroutine to type or display one ASCII character on the
; console/terminal.  In both cases the character is in the A
; accumulator, but the subroutine need not preserve the contents of the
; other registers.  It is assumed that the character input routine will
; simultaneously display each character as it is input; if this is not
; the case, the jmp instruction in location 0106 may be converted to a
; JSR, so that each character input flows through the output subroutine
; (which in this case must preserve A) before being fed to TINY.
; Users with terminals using Baudot or some other non-ASCII code should
; perform the character conversion in the Input and Output subroutines.
; If your console is a CRT and/or you have no need to output or
; display extra pad characters with each Carriage Return and Linefeed,
; you may intercept these in the output routine to bypass their
; display.  Each input prompt by TINY is followed by an "X-ON"
; character (ASCII DC1) with the sign bit set to 1 (all other
; characters except rubout are output with the sign bit set to 0) so
; these are also readily detected and deleted from the output stream.
; Appendix C shows how to perform these tests.
;

INCHAR		jmp	CIN
OUTCHAR		jmp	COUT

;
; A third subroutine provided by you is optional, and gives TINY
; a means to test for the BREAK condition in your system.  Appendix C
; shows how this subroutine may be implemented for different types of
; I/O devices.  If you choose to omit this subroutine, TINY will assume
; that a BREAK condition never happens; to include it, simply replace
; locations 010C-010E with a jmp to your subroutine, which returns with
; the break condition recorded in the Carry flag (1 = BREAK, 0 = no
; BREAK).  The Break condition is used to interrupt program execution,
; or to prematurely terminate a LIST operation.  Tiny responds to the
; Break condition any time in the LIST, or just before examining the
; next statement in program execution.  If a LIST statement included
; within a program is aborted by the Break condition, the Break
; condition must be held over to the next statement fetch (or repeated)
; to stop program execution also.
;

TSTBRK		nop	;dummy function always returns "no break"
		clc	;default to no-break
		rts

; Next are ASCII characters that the user can change to alter which
; keys do what sort of editing functions.
;
; The Backspace code is located near the beginning of the program
; (location 010F), and is set by default to "left-arrow" or ASCII
; Underline (shift-O on your Teletype).  To change this to the ASCII
; Standard Backspace code (or anything else you choose), the contents
; of location 010F may be changed to the desired code.  Similarly the
; Cancel code is located at memory address 0110, and is set by default
; to the ASCII Cancel code (Control-X). 
;
BACKKEY		.byte	BS
CANKEY		.byte	CTRL_X
;
; When Tiny ends a line (either input or output), it types a CR,
; two pad characters, a Linefeed, and one more pad character.  The pad
; character used is defined by the sign bit in location 0111, and is
; set by default to the "Rubout" or Delete code (hex FF; Location 0111
; Bit 7 = 1) to minimize synchronization loss for bit-banger I/O
; routines.  The pad character may be changed to a Null (hex 00) by
; setting the sign of location 0111 to 0.  The remainder of this byte
; defines the number of Pad characters between the CR and linefeed.
; More than two pad characters may be required if large user programs
; are to be loaded from tape (see comments on Tape Mode, below).
;

OutPad		.byte	$82

;
; TINY BASIC has a provision for suppressing output (in
; particular line prompts) when using paper tape for loading a program
; or inputting data.  This is activated by the occurrence of a Linefeed
; in the input stream (note that the user normally has no cause to type
; a Linefeed since it is echoed in response to each CR), and disables
; all output (including program output) until the tape mode is
; deactivated.  This is especially useful in half-duplex I/O systems
; such as that supported by Mikbug, since any output would interfere
; with incoming tape data.  The tape mode is turned off by the
; occurrence of an X-OFF character (ASCII DC3, or Control-S) in the
; input, by the termination of an executing program due to an error, or
; after the execution of any statement or command which leaves Tiny in
; the command mode.  The tape mode may be disabled completely by
; replacing the contents of memory location 0112 with a 00.
;
SupOut		.byte	$80
;
; Memory location 0113 is of interest to those 6800 users with
; extensive operating systems.  Normally Tiny reserves 32 bytes of
; stack space for use by the interpreter and I/O routines (including
; interrupts).  Up to half of these may be used by Tiny in normal
; operation, leaving not more than 16 bytes on the stack for I/O.  If
; your system allows nested interrupts or uses much more than ten or
; twelve stack bytes for any purpose, additional space must be
; allocated on the stack.  Location 0113 contains the reserve stack
; space parameter used by Tiny, and is normally set to 32 (hex 20).  If
; your system requires more reserve, this value should be augmented
; accordingly before attempting to run the interpreter.
;
StackReserve	.byte	$04
;
; 0114            Subroutine to read one Byte
;                   from RAM to A (address in X)
; 0118            Subroutine to store A into RAM
;                   at address in X
;
; These are not directly used by the 6502 assembly language version
; of the IL interpreter, but do get used by BASIC programs to
; implement things like PEEK and POKE.
;
	stx	pp_temp
	bcc	BOB1
	stx	pp_temp
	sta	(ExStackPtr+1),y
	rts
BOB1	lda	(ExStackPtr+1),y
	ldy	#0
	rts
;
; Original code from disassembly, to verify my code is the same...
;
;2014       DB  86,C3,  90,05,  86,C3,  91,C2, 60, B1
;201E              ; 1 
;201E       DB  C2
;201F              ; 1 
;201F       DB  A0,00,60
;
;
; This is the IL vector table.  The 7th entry and on are directly
; indexed.  The first 6 entries take a rather odd route, and their
; index is calculated in a different manner.
;
il_dispatch
	.word	L004		; 2162 - BR ($40 - $5F)
	.word	L005		; 2164 - BR ($60 - $7F)
	.word	DoBC		; 21D8 - BC ($80 - $9F) 
	.word	DoBV		; 2205 - BV ($A0 - $BF)
	.word	DoBN		; 2233 - BN ($C0 - $DF)
	.word	DoBE		; 21FD - BE ($E0 - $FF)
;
	.word	DoNoOp		; 239F - NO ($08)
	.word	DoLB		; 2742 - LB n ($09)
	.word	DoLN		; 273F - LN ($0a)
	.word	DoDS		; 237A - DS ($0b)
	.word	DoSP		; 24FC - SP ($0c)
	.word	PopExByte	; 2395
	.word	DoNoOp		; 239F - Undefined
	.word	DoNoOp		; 239F - Undefined
	.word	DoSB		; 26BD - SB ($10)
	.word	DoRB		; 26C1 - RB ($11)
	.word	DoFV		; 268A - FV ($12)
	.word	DoSV		; 269B - SV ($13)
	.word	DoGS		; 26E9 - GS ($14)
	.word	DoRS		; 2361 - RS ($15)
	.word	DoGO		; 2351 - GO ($16)
	.word	DoNE		; 2641 - NE ($17)
	.word	DoAD		; 2652 - AD ($18)
	.word	DoSU		; 264F - SU ($19)
	.word	DoMP		; 2662 - MP ($1a)
	.word	DoDV		; 25E7 - DV ($1b)
	.word	DoCP		; 22CD - CP ($1c)
	.word	DoNX		; 2306 - NX ($1d)
	.word	DoNoOp		; 239F - Undefined
	.word	DoLS		; 2415 - LS ($1f)
	.word	DoPN		; 23A7 - PN ($20)
	.word	DoPQ		; 22B7 - PQ ($21)
	.word	DoPT		; 22BF - PT ($22)
	.word	DoNL		; 2483 - NL ($23)
	.word	DoPC		; 22A1 - PC ($24)
	.word	DoNoOp		; 239F - Undefined
	.word	DoNoOp		; 239F - Undefined
	.word	DoGL		; 24A8 - GL ($27)
	.word	L037	; 274F - Beats me... I don't see this opcode in C version
	.word	L038	; 274D - Beats me... same excuse
	.word	DoIL		; 2507 - IL ($2a)
	.word	DoMT		; 20AA - MT ($2b)
	.word	DoXQ		; 2337 - XQ ($2c)
	.word	WarmEntry	; 20BD - WS ($2d)
	.word	DoUS		; 271B - US ($2e)
	.word	DoRT		; 26B1 - RT ($2f)
;
AtMsg	.byte	" AT "
	.byte	$80
;
; This contains the start of the IL code that the IL interpreter
; is supposed to read/execute.  By default, it points to the 
; Tiny Basic IL at the end of this file.
;
IlStart	.word	DefaultIL
;
;**********************************************************************
; This is the cold-start entry point.
;
ColdEntry
	lda	#0		;always force to page boundary...
	sta	UserProg
	sta	EndUser
	lda	#((codeend + $ff) >> 8)	;...one page past end of code
	sta	UserProg+1
	sta	EndUser+1
;
; Looks like an attempt to find the end of memory and size it.
; Non-destructive to whatever might have been there.
;
	ldy	#1
L171	lda	(EndUser),y
	tax			;save for restoration
	eor	#$FF
	sta	(EndUser),y
	cmp	(EndUser),y
	php
	txa			;restore
	sta	(EndUser),y
	inc	EndUser
	bne	L170
	inc	EndUser+1
L170	plp
	beq	L171
	dey
;
; Found first memory location that failed.
;
DoMT	cld
	lda	UserProg
	adc	StackReserve
	sta	EndProg
	tya
	adc	UserProg+1
	sta	EndProg+1
	tya
	sta	(UserProg),y
	iny
	sta	(UserProg),y
;
;**********************************************************************
; This is the warm-start entry point.
;
WarmEntry
	lda	EndUser
	sta	GosubStkPtr
	sta	GoStkTop
	lda	EndUser+1
	sta	GosubStkPtr+1
	sta	GoStkTop+1
	jsr	CrLf
L053:	lda	IlStart		;set pointer to default IL program
	sta	IlPtr
	lda	IlStart+1
	sta	IlPtr+1
	lda	#(ExpressStackTop & $ff)
	sta	ExStackPtr
	lda	#(ExpressStack & $ff)
	sta	ExStackBottm
	ldx	#(ExpressStackTop >> 8)
;
; Tricky... even though we're loading the high byte of the
; address of ExStackTop, this logic assumes it is zero!
;
	stx	Running		;not running right now
	stx	ExStackPtr+1
	dex
	txs
;
; This is the main IL processing loop.  Get the next IL opcode,
; call the interpreter, then do it again.
;
IlLoop	cld			;paranoid?
	jsr	GetIlByte	;get the next IL opcode
	jsr	Interp		;interpret the opcode
	jmp	IlLoop		;...and do it again!
;
; Unknown data bytes.  Can't find any reference to them yet.
; Tom thinks they might have been a serial number.
;
	.byte	$83, $65
;
;**********************************************************************
; This interprets the current IL opcode in A.  This assumes Y is 0,
; which it should be from the call to GetIlByte.
;
Interp	cmp	#RT+1		;Is it a simple opcode to handle?
	bcs	L057		;Nope.  Jump elsewhere.
	cmp	#SX7+1		;Is it an SX opcode?
	bcc	DoSX		;Yes... handle differently
	asl	a		;else, do a table lookup
	tax
;
; Note to self... this actually looks up the pointer from the
; table, but the base address of the lookup is before the
; actual table.  The opcode index is in X.  Look up the opcode,
; then do an indirect call to the subroutine.
;
L066	lda	il_dispatch-3,x	;pointer should be $201F
	pha
	lda	il_dispatch-4,x	;pointer should be $201E
	pha
	php
	rti			;Call the opcode handler
;
;**********************************************************************
; Handler for the SX opcode.  The opcode value is a number from 0 to 7
; which indicates which computation stack entry to swap with the top
; of the stack.
;
DoSX	adc	ExStackPtr
	tax
	lda	(ExStackPtr),y	;Get current byte at that offset
	pha			;save for later
	lda	$00,x		;get current top of stack...
	sta	(ExStackPtr),y	;...save it back into stack
	pla
	sta	$00,x		;and save new top of stack value.
	rts
;
;**********************************************************************
; Error handler
;
Error	jsr	CrLf	; 2487
	lda	#'!'
	jsr	OUTCHAR		;print "!" to start error message
;
; Compute the offset into the IL area where the error ocurred.  When
; IL gets an error, it's reported as the address in the IL program
; counter where the errored instruction is located.
;
	lda	IlPtr
	sec
	sbc	IlStart
	tax
	lda	IlPtr+1
	sbc	IlStart+1
	jsr	PrintPositive	;X = MSB, A = LSB - print address
;
	lda	Running		;are we running a program?
	beq	nolinnm		;nope, so don't print the line number
;
; Print the phrase " AT " followed by the current line number
;
	lda	#(AtMsg & $ff)
	sta	IlPtr
	lda	#(AtMsg >> 8)
	sta	IlPtr+1
	jsr	DoPC
;
	ldx	LineNumber	;pick up the line number
	lda	LineNumber+1
	jsr	PrintPositive	;print line number

nolinnm	lda	#BELL		;"Hey, BOZO, there's an error!"
	jsr	OUTCHAR
	jsr	CrLf
L139	lda	GoStkTop
	sta	GosubStkPtr
	lda	GoStkTop+1
	sta	GosubStkPtr+1
	jmp	L053	; 20CC
;
; Make sure we aren't about to underflow the expression stack,
; then return X bumped down one 16 bit value - ???
;
L146	ldx	#(ExpressStackTop-4)
L140	cpx	ExStackPtr
L062	bcc	Error
	ldx	ExStackPtr
	inc	ExStackPtr
	inc	ExStackPtr
	clc
	rts
;
; These are the entry points for the BR opcode handler.  The
; first is for opcodes $40-$5F.  The second is for opcodes
; from $60-$7F.  Note that an opcode of $60 implies a relative
; branch of "0" which is illegal, and results in an error.
;
L004	dec	Temp1+1
L005	lda	Temp1+1
	beq	Error		;0 is bad.  Otherwise, fall into...
;
; This handles a Jump instruction.  Load the new destination
; IL address and put into the IlPtr.
;
ProcJ	lda	Temp1
	sta	IlPtr
	lda	Temp1+1
	sta	IlPtr+1
	rts
;
; Handle more complex IL opcodes
;
L057	cmp	#BR		;Start of BR instructions
	bcs	L059		;Value is >= $40
;
; The opcode is between $31 and $3f inclusive
;
	pha
	jsr	GetIlByte	;Get lower 8 bits of target offset
	adc	IlStart
	sta	Temp1
	pla
	pha
	and	#$07		;get upper 3 bits of target offset
	adc	IlStart+1
	sta	Temp1+1		;Temp1 contains the target IL
	pla
;
; Now we have the opcode in A again.  If bit 3 is set, then this
; is a J(ump) instruction.  If not set, it's a JS (Jump Subroutine).
;
	and	#$08
	bne	ProcJ		;it's a Jump.
;
; Process a JS opcode.  The target address is already in Temp1.
;
	lda	Temp1		;Swap Temp1 with IlPtr
	ldx	IlPtr
	sta	IlPtr
	stx	Temp1
	lda	Temp1+1
	ldx	IlPtr+1
	sta	IlPtr+1
	stx	Temp1+1
;
; Decrement the gosub stack pointer, then make sure we still
; have room for this new entry.
;
L160	lda	GosubStkPtr
	sbc	#1
	sta	GosubStkPtr
	bcs	L061
	dec	GosubStkPtr+1
L061	cmp	EndProg
	lda	GosubStkPtr+1
	sbc	EndProg+1
	bcc	L062		;gosub stack overflow
;
; Save return address on the gosub stack.
;
	lda	Temp1
	sta	(GosubStkPtr),y	
	iny
	lda	Temp1+1
	sta	(GosubStkPtr),y
	rts
;
; Opcode is greater than $40
;
L059	pha			;save opcode
	lsr	a		;move top nibble into bottom
	lsr	a
	lsr	a
	lsr	a
	and	#$0E		;only keep top three bits
	tax			;this will be an index in jump table!
;
; Just a quick note about X now.  It has a value of 2, 4, 6, 8, 10, 12,
; or 14.  Since the jump table really begins 4 bytes before the label,
; we know that X can not contain a 2 or else the vector would be bogus.
; That leaves 6 possible values, which are used to index into the first
; six entries of the jump table to get to the next part of the handler.
;
; BTW, the next 13 lines of code (until the jmp L066) makes little
; sense to me.  Still need to think about this for a while to understand
; what Tom is really doing here.  It's setting up a relative IL branch
; and is saving the address in Temp1, but the logic confuses me.
;
	pla			;restore opcode
	cmp	#$60
	and	#$1F
	bcs	L064		;branch if A >= $60
	ora	#$E0
L064	clc
	beq	L065		;branch if A >= $60 && bottom 5 bits all 0
	adc	IlPtr
	sta	Temp1
	tya
	adc	IlPtr+1
L065	sta	Temp1+1
	jmp	L066		;use the first entries in the jump table
;
; BC handler.  The ASCII character string in IL  following this
; opcode is compared to the string beginning with the current position
; of the BASIC pointer, ignoring blanks in BASIC program.  The
; comparison continues until either a mismatch, or an IL byte is reached
; with the most significant bit set to one.  This is the last byte of
; the string in the IL, compared as a 7-bit character; if equal, the
; BASIC pointer is positioned after the last matching character in the
; BASIC program and the IL continues with the next instruction in
; sequence.  Otherwise the BASIC pointer is not altered and the low five
; bits of the Branch opcode are added to the IL program counter to form
; the address of the next IL instruction.  If the strings do not match
; and the branch offset is zero an error stop occurs.
;
DoBC	lda	LinePtr
	sta	Dest
	lda	LinePtr+1
	sta	Dest+1
L167	jsr	L162	; 2225
	jsr	FetchByte	; 2214
	eor	(IlPtr),y
	tax
	jsr	GetIlByte	; 22F9
	txa
	beq	L167	; 21E0
	asl	a
	beq	L168	; 2204
	lda	Dest
	sta	LinePtr
	lda	Dest+1
	sta	LinePtr+1
L163	jmp	L005	; 2164
;
; Branch if Not Endline.  If the next non-blank character pointed to by
; the BASIC pointer is a carriage return, the IL program advances to the
; next instruction in sequence; otherwise the low five bits of the
; opcode (if not 0) are added to the IL program counter to form the
; address of next IL instruction.  In either case the BASIC pointer
; is left pointing to the first non-blank character; this
; instruction will not pass over the carriage return, which must
; remain for testing by the NX instruction.  As with the other
; conditional branches, the branch may only advance the IL program
; counter from 1 to 31 bytes; an offset of zero results in an error
; stop.
;
DoBE	jsr	L162		;get next non-space character
	cmp	#CR
	bne	L163		;not eol, so take branch
L168	rts
;
; Branch if Not Variable.  If the next non-blank character pointed to
; by the BASIC pointer is a capital letter, its ASCII code is [doubled
; and] pushed onto the expression stack and the IL program advances to
; next instruction in sequence, leaving the BASIC pointer positioned
; after the letter; if not a letter the branch is taken and BASIC
; pointer is left pointing to that character. An error stop occurs
; if the next character is not a letter and the offset of the branch
; is zero, or on stack overflow.
;
DoBV	jsr	L162		;Get next non-space character
	cmp	#'Z'+1
	bcs	L163		;branch if not a variable
	cmp	#'A'
	bcc	L163		;branch if not a variable
	asl	a
	jsr	PushExByte	;push index onto stack
;
; Another mini subroutine.  This gets the character currently
; pointed to by LinePtr, increments LinePtr, returns with the
; character in A, *and* Z set if the character is a CR.  C
; is always clear upon return.
;
FetchByte
	ldy	#0
	lda	(LinePtr),y	;get character
	inc	LinePtr		;move to next location
	bne	checkcr
	inc	LinePtr+1
checkcr	cmp	#CR		;end of the line?
	clc
	rts
;
;**********************************************************************
; Call this to find the next non-space in (lineptr),y
;
L164	jsr	FetchByte	; 2214
L162	lda	(LinePtr),y
	cmp	#' '
	beq	L164	; 2222
	cmp	#':'		;0x3a
	clc
	bpl	L165	; 2232
	cmp	#'0'
L165	rts
;
; Branch if Not a Number.  If the next non-blank character pointed to
; by the BASIC pointer is not a decimal digit, the low five bits of the
; opcode are added to the IL program counter, or if zero an error
; stop occurs.  If the next character is a digit, then it and all
; decimal digits following it (ignoring blanks) are converted to a
; 16-bit binary number which is pushed onto the expression stack.  In
; either case the BASIC pointer is positioned at the next character
; which is neither blank nor digit.  Stack overflow will result in an
; error stop.
;
DoBN	jsr	L162	; 2225
	bcc	L163	; 21FA
	sty	Temp1
	sty	Temp1+1
L166	lda	Temp1
	ldx	Temp1+1
	asl	Temp1
	rol	Temp1+1
	asl	Temp1
	rol	Temp1+1
	clc
	adc	Temp1
	sta	Temp1
	txa
	adc	Temp1+1
	asl	Temp1
	rol	a
	sta	Temp1+1
	jsr	FetchByte
	and	#$0F
	adc	Temp1
	sta	Temp1
	tya
	adc	Temp1+1
	sta	Temp1+1
	jsr	L162	; 2225
	bcs	L166	; 223C
	jmp	L117	; 2380
;
; Does something with line numbers
;
L092	jsr	DoSP		;Pop top 16 bit value from stack...
	lda	Temp1		;...and see if the value is zero.
	ora	Temp1+1
	beq	L111		;If zero, branch to error handler
;
L158	lda	UserProg	;Set starting location of program
	sta	LinePtr
	lda	UserProg+1
	sta	LinePtr+1

L114	jsr	L087	; 236D
	beq	L112	; 2293
	lda	LineNumber
	cmp	Temp1
	lda	LineNumber+1
	sbc	Temp1+1
	bcs	L112	; 2293

L113	jsr	FetchByte	; 2214
	bne	L113	; 228B
	jmp	L114	; 227C

L112	lda	LineNumber
	eor	Temp1
	bne	L115	; 229D
	lda	LineNumber+1
	eor	Temp1+1
L115	rts
;
; This is part of the PC handler.  If the last byte picked up is
; positive (ie, not end of string), then jump here.  This calls the
; print routine, then returns.
;
L082	jsr	InDoPc
;
;**********************************************************************
; Handler for PC opcode.  The literal string to print directly
; follows the opcode.  Print characters until we find one with
; the MSB set.
;
DoPC	jsr	GetIlByte	;get byte to print
	bpl	L082		;if not end, do weird stuff
InDoPc	inc	CharCount
	bmi	L081
	jmp	OUTCHAR		;let it return to caller
L081	dec	CharCount
L126	rts




L127	cmp	#'"'		;quote?
	beq	L126	; 22AF
	jsr	InDoPc	; 22A6
;
;**********************************************************************
; The ASCII characters beginning with the current position of BASIC
; pointer are printed on the console.  The string to be printed is
; terminated by quotation mark ("), and the BASIC pointer is left at
; the character following the terminal quote.  An error stop occurs if
; a carriage return is imbedded in the string.
;
DoPQ	jsr	FetchByte	; 2214
	bne	L127	; 22B0
L111	jmp	Error
;
;**********************************************************************
; Print one or more spaces on the console, ending at the next multiple
; of eight character positions (from the left margin).
;
DoPT	lda	#' '
	jsr	InDoPc		;output a space
	lda	CharCount
	and	#$87
	bmi	L126	; 22AF
	bne	DoPT	; 22BF
	rts
;
;**********************************************************************
; The number in the top two bytes of the expression stack is compared
; to (subtracted from) the number in the 4th and fifth bytes of the
; stack, and the result is determined to be Greater, Equal, or Less.
; The low three bits of the third byte mask a conditional skip in the
; IL program to test these conditions; if the result corresponds to a
; one bit, the next byte of the IL code is skipped and not executed.
; The three bits correspond to the conditions as follows:
;
;         bit 0   Result is Less
;         bit 1   Result is Equal
;         bit 2   Result is Greater
;
; Whether the skip is taken or not, all five bytes are deleted from
; the stack. This is a signed (two's complement) comparison so that
; any positive number is greater than any negative number. Multiple
; conditions, such as greater-than-or-equal or unequal (i.e.greater-
; than-or-less-than), may be tested by forming the condition mask
; byte of the sum of the respective bits. In particular, a mask byte
; of 7 will force an unconditional skip and a mask byte of 0 will
; force no skip. The other 5 bits of the control byte are ignored.
; Stack underflow results in an error stop.
;
DoCP	ldx	#$7B
	jsr	L140	; 2156
	inc	ExStackPtr
	inc	ExStackPtr
	inc	ExStackPtr
	sec
	lda	$03,x
	sbc	$00,x
	sta	$00,x
	lda	$04,x
	sbc	$01,x
	bvc	L141	; 22E9
	eor	#$80
	ora	#$01
L141	bmi	L142	; 22F5
	bne	L143	; 22F1
	ora	$00,x
	beq	L144	; 22F3
L143	lsr	$02,x
L144	lsr	$02,x
L142	lsr	$02,x
	bcc	L145	; 2305
;
;**********************************************************************
; Get the next byte in the IL code.  Moves pointer to the
; next byte, then sets flags to reflect the contents of
; the accumulator.  Y is always set to 0 upon return.
;
GetIlByte
	ldy	#0
	lda	(IlPtr),y
	inc	IlPtr
	bne	L063	; 2303
	inc	IlPtr+1
L063	ora	#0		;Set flags
L145	rts
;
;**********************************************************************
; Advance to next line in the BASIC program, if in RUN mode, or
; restart the IL program if in the command mode. The remainder
; of the current line is ignored. In the Run mode if there is
; another line it becomes current with the pointer positioned at
; its beginning. At this time, if the Break condition returns true,
; execution is aborted and the IL program is restarted after
; printing an error message. Otherwise IL execution proceeds from
; the saved IL address (see the XQ instruction). If there are no
; more BASIC statements in the program an error stop occurs.
;
DoNX	lda	Running
	beq	L135		;not running!

L136	jsr	FetchByte	; 2214
	bne	L136	; 230A
	jsr	L087	; 236D
	beq	L088	; 232F
L156	jsr	MarkRun
	jsr	TSTBRK	; 200C
	bcs	L138	; 2325
	lda	$C4
	sta	IlPtr
	lda	$C5
	sta	IlPtr+1
	rts


L138	lda	IlStart
	sta	IlPtr
	lda	IlStart+1
	sta	IlPtr+1
L088	jmp	Error	; 2114

L135	sta	CharCount
	jmp	L139	; 2149
;
;**********************************************************************
; Turns on RUN mode. This instruction also saves the current
; value of the IL program counter for use of the NX instruction,
; and sets the BASIC pointer to the beginning of the BASIC
; program space. An error stop occurs if there is no BASIC
; program. This instruction must be executed at least once before
; the first execution of a NX instruction.
;
DoXQ	lda	UserProg
	sta	LinePtr
	lda	UserProg+1
	sta	LinePtr+1
	jsr	L087		;See if there is a program or not
	beq	L088		;no program, so it's an error
	lda	IlPtr
	sta	$C4
	lda	IlPtr+1
	sta	$C5
;
; This is a mini-subroutine to turn on the Running flag.
;
MarkRun	lda	#$01
	sta	Running		;run flag?
	rts
;
;**********************************************************************
; Make current the BASIC line whose line number is equal to the value
; of the top two bytes in the expression stack.  That is, the top two
; bytes are popped off the computational stack, and the BASIC program
; is searched until a matching line number is found.  The BASIC pointer
; is then positioned at the beginning of that line and the RUN mode
; flag is turned on.  Stack underflow and non-existent BASIC line
; result in error stops.
;
DoGO	jsr	L092	; 226B
	beq	L156	; 2314
L159	lda	Temp1
	sta	LineNumber
	lda	Temp1+1
	sta	LineNumber+1
	jmp	Error	; 2114
;
;**********************************************************************
; Pop the top two bytes off the BASIC region of the control stack,
; making them the current line number.  Set the BASIC pointer at the
; beginning of that line.  Note that this is the line containing the
; GOSUB which caused the line number to be saved.  As with the GS
; opcode, it is essential that the IL region of the control stack be
; empty.  If the line number popped off the stack does not correspond
; to a line in the BASIC program an error stop occurs. An error stop
; also results from stack underflow.
;
DoRS	jsr	L045	; 26FD
	jsr	L157	; 26F4
	jsr	L158	; 2274
	bne	L159	; 2356
	rts
;
;**********************************************************************
; Get line numbers from somewhere, save them in LineNumber,
; then set/clear the Z flag if the number is zero or not.
; On entry, it is assumed if Y = 0, then (LinePtr),Y will point to
; the binary line number of a line.
;
L087	jsr	FetchByte		;get next byte pointer to by (LinePtr),Y y=0
	sta	LineNumber
	jsr	FetchByte
	sta	LineNumber+1
	ora	LineNumber
	rts
;
;**********************************************************************
; Duplicate Top Number (two bytes) on Stack.  An error stop will occur
; if there are less than 2 bytes (1 int) on the expression stack or if
; the stack overflows.
;
DoDS	jsr	DoSP	; 24FC
	jsr	L117	; 2380
L117	lda	Temp1+1
L084	jsr	PushExByte	; 2387
	lda	Temp1
;
;**********************************************************************
; Push the byte in A onto the expression stack.  Decrement the
; stack pointer and make sure we haven't just overflowed.
;
PushExByte
	ldx	ExStackPtr	;get current stack pointer...
	dex			;...move down one entry...
	sta	$00,x		;...save it onto stack...
	stx	ExStackPtr	;...and save the pointer
	cpx	ExStackBottm
	bne	DoNoOp		;all done
L086	jmp	Error
;
;**********************************************************************
; Pop one byte off the top of the expression stack.  Generates
; an error if the stack is underflowed.
;
PopExByte
	ldx	ExStackPtr	;current stack pointer
	cpx	#(ExpressStackTop & $ff)
	bpl	L086		;did we under-run the stack?
	lda	$00,x		;get value from stack
	inc	ExStackPtr	;point to next entry
;
; This rts is also a No-Op handler
;
DoNoOp	rts
;
;**********************************************************************
; The value in A & X are printed as an unsigned decimal number.  A is
; LSB, X is MSB.  Since the sign is not printed, the value must not
; have the MSBit set.
;
PrintPositive
	sta	Temp1+1
	stx	Temp1
	jmp	L072	; 23B8
;
;**********************************************************************
; The number represented by the top two bytes of the expression stack
; is printed in decimal with leading zero suppression.  If it is
; negative, it is preceded by a minus sign and the magnitude is
; printed.  Stack underflow is possible.
;
DoPN	ldx	ExStackPtr
	lda	$01,x
	bpl	L128		;branch if positive number
;
; Else, make two's complement and print the negative sign.
;
	jsr	DoNE	; 2641
	lda	#'-'
	jsr	InDoPc		;print minus sign
L128	jsr	DoSP	; 24FC
;
; Print the contents of Temp1 as a decimal number.
;
L072	lda	#$1F
	sta	Dest
	sta	$BA
	lda	#$2A
	sta	Dest+1
	sta	$BB
	ldx	Temp1
	ldy	Temp1+1
	sec
L073	inc	Dest
	txa
	sbc	#(10000 & $ff)
	tax
	tya
	sbc	#(10000 >> 8)
	tay
	bcs	L073	; 23C9
L074	dec	Dest+1
	txa
	adc	#(1000 & $ff)
	tax
	tya
	adc	#(1000 >> 8)
	tay
	bcc	L074	; 23D5
	txa
L076	sec
L075	inc	$BA
	sbc	#100
	bcs	L075	; 23E3
	dey
	bpl	L076	; 23E2
L077	dec	$BB
	adc	#10
	bcc	L077	; 23EC
	ora	#$30
	sta	Temp1
	lda	#$20
	sta	Temp1+1
	ldx	#$FB
L080	stx	pp_temp
	lda	Temp1+1,x
	ora	Temp1+1
	cmp	#$20
	beq	L078	; 240F
	ldy	#'0'
	sty	Temp1+1
	ora	Temp1+1
	jsr	InDoPc	; 22A6
L078	ldx	pp_temp
	inx
	bne	L080	; 23FC
	rts
;
;**********************************************************************
; The expression stack is assumed to have two 2-byte numbers.  The top
; number is the line number of the last line to be listed, and the next
; is the line number of the first line to be listed.  If the specified
; line numbers do not exist in the program, the next available line
; (i.e. with the next higher line number) is assumed instead in each
; case.  If the last line to be listed comes before the first, no lines
; are listed.  If Break condition comes true during a List operation,
; the remainder of the listing is aborted.  Zero is not a valid line
; number, and an error stop occurs if either line number specification
; is zero.  The line number specifications are deleted from the stack.
;
DoLS	lda	LinePtr+1		;save the pointer to the current line
	pha
	lda	LinePtr
	pha
;
	lda	UserProg		;set ptr to start of program
	sta	LinePtr
	lda	UserProg+1
	sta	LinePtr+1

	lda	EndProg
	ldx	EndProg+1
	jsr	L129			;???
	beq	L130			;if Z set, expression stack empty!
	jsr	L129			;???
;
; See if LinePtr has passed the end of the user program.  If so, 
; jump to L131 to finish, otherwise print the current line.
;
L130	lda	LinePtr
	sec
	sbc	Temp2
	lda	LinePtr+1
	sbc	Temp2+1
	bcs	L131			;past the end
;
	jsr	L087			;Get line number of current line
	beq	L131			;zero indicates end?
;
; Print the line number in decimal, followed by a space.
;
	ldx	LineNumber
	lda	LineNumber+1
	jsr	PrintPositive		;print line number in decimal
	lda	#' '
L133	jsr	InDoPc			;print a space
	jsr	TSTBRK			;did user hit BREAK?
	bcs	L131			;yes!
	jsr	FetchByte		;get next char on line...
	bne	L133			;if Z not set, then not at EOL
	jsr	DoNL			;force a newline
	jmp	L130			;...and continue the loop.
;
; Used only by the DoLS routine.  Called with the pointer to the
; end of the current basic program in A (LSB) and X (MSB).  When
; this exits, Temp2 points to the end of the program + 1.
;
L129	sta	Temp2			;add one to the pointer, then...
	inc	Temp2			;...save it into Temp2
	bne	L134
	inx
L134	stx	Temp2+1
;
; See if expression stack is empty
;
	ldy	ExStackPtr
	cpy	#(ExpressStackTop & $ff)
	beq	L125			;branch if expression stack is empty
;
	jsr	L092	; 226B
L093	lda	LinePtr
	ldx	LinePtr+1
	sec
	sbc	#$02
	bcs	L109	; 2477
	dex
L109	sta	LinePtr
	jmp	StxLinePtr
;
; All done.  Restore where we were, then return.
;
L131	pla
	sta	LinePtr
	pla
	sta	LinePtr+1
L125	rts
;
;**********************************************************************
; Output a carriage-return-linefeed sequence to the console.
;
DoNL	lda	CharCount
	bmi	L125		;only up to 127 characters
;
;**********************************************************************
; Do a CR/LF.  After sending the CR, see what character we need to
; use as a pad, then insert the appropriate number of pads before
; sending the LF.
;
CrLf	lda	#CR		;force a new line
	jsr	OUTCHAR
	lda	OutPad
	and	#$7F
	sta	CharCount	;save count for loop
	beq	L067		;if zero, don't pad at all
L069	jsr	Padding
	dec	CharCount
	bne	L069		;loop until we sent enough pads
L067	lda	#LF		;output LF and then another pad
	jmp	L070
;
;**********************************************************************
; Main routine to get a line of text from the user
;
L120	ldy	SupOut
L119	sty	CharCount
	bcs	KeyLoop
;
;**********************************************************************
; ASCII characters are accepted from console input to fill the line
; buffer.  If the line length exceeds the available space, the excess
; characters are ignored and bell characters are output.  The line is
; terminated by a carriage return.  On completing one line of input,
; the BASIC pointer is set to point to the first character in the input
; line buffer, and a carriage-return-linefeed sequence is [not] output.
;
DoGL	lda	#(ExpressStack & $ff)
	sta	LinePtr
	sta	ExStackBottm
	sty	LinePtr+1
	jsr	L117
KeyLoop	eor	RandNum			;Feeding the random number?
	sta	RandNum
	jsr	INCHAR			;Get a key from the user
	ldy	#00
	ldx	ExStackBottm
	and	#$7F			;remove parity
	beq	KeyLoop			;loop if a nul byte
;
	cmp	#DEL
	beq	KeyLoop
	cmp	#$13
	beq	L119
	cmp	#LF
	beq	L120
	cmp	CANKEY			;cancel line key?
	beq	GotCanc
	cmp	BACKKEY			;backspace (delete) key?
	bne	NotBS
;
; User pressed the backspace key.  If we're not already at the bottom
; of the stack, delete it.
;
	cpx	#(ExpressStack & $ff)
	bne	L123			;string isn't empty, so continue
GotCanc	ldx	LinePtr
	sty	CharCount
	lda	#CR
NotBS	cpx	ExStackPtr
	bmi	L124
	lda	#BELL
	jsr	InDoPc			;beep at the bozo
	jmp	KeyLoop			;get/process next key
;
; Save the key!  Character is in A, index in X.  Note that X is the
; index from the start of page zero, not from the start of the buffer.
;
L124	sta	$00,x			;save it
	inx				;move to next char
	inx				;inc extra time for dex...
;
; Delete the current character
;
L123	dex
	stx	ExStackBottm
	cmp	#CR
	bne	KeyLoop			;not a CR, so go process next key
;
; We just saved a CR.  Time to finish the line.
;
	jsr	DoNL	; 2483
;
;**********************************************************************
; The top two bytes are removed from the expression stack and stored
; in Temp1.  Underflow results in an error stop.
;
DoSP	jsr	PopExByte	; 2395
	sta	Temp1
	jsr	PopExByte	; 2395
	sta	Temp1+1
	rts
;
;**********************************************************************
; Beginning with the current position of the BASIC pointer and
; continuing to the [end of it], the line is inserted into the BASIC
; program space; for a line number, the top two bytes of the expression
; stack are used. If this number matches a line already in the program
; it is deleted and the new one replaces it.  If the new line consists
; of only a carriage return, it is not inserted, though any previous
; line with the same number will have been deleted. The lines are
; maintained in the program space sorted by line number. If the new
; line to be inserted is a different size than the old line being
; replaced, the remainder of the program is shifted over to make room
; or to close up the gap as necessary.  If there is insufficient memory
; to fit in the new line, the program space is unchanged and an error
; stop occurs (with the IL address decremented). A normal error stop
; occurs on expression stack underflow or if the number is zero, which
; is not a valid line number. After completing the insertion, the IL
; program is restarted in the command mode.
;
DoIL	jsr	L091	; 26D6
	jsr	L092	; 226B
	php
	jsr	L093	; 246D
	sta	Dest
	stx	Dest+1
	lda	Temp1
	sta	Temp2
	lda	Temp1+1
	sta	Temp2+1
	ldx	#0
	plp
	bne	L094	; 252D
	jsr	L087	; 236D
	dex
	dex
L095	dex
	jsr	FetchByte	; 2214
	bne	L095	; 2527
L094	sty	LineNumber
	sty	LineNumber+1
	jsr	L091	; 26D6
	lda	#CR
	cmp	(LinePtr),y
	beq	L096	; 254B
	inx
	inx
	inx
L097	inx
	iny
	cmp	(LinePtr),y
	bne	L097	; 253D
	lda	Temp2
	sta	LineNumber
	lda	Temp2+1
	sta	LineNumber+1
L096	lda	Dest
	sta	Temp1
	lda	Dest+1
	sta	Temp1+1
	clc
	ldy	#0
	txa
	beq	L098	; 25C7
	bpl	L099	; 2584
	adc	Source
	sta	Dest
	lda	Source+1
	sbc	#0
	sta	Dest+1
L103	lda	(Source),y
	sta	(Dest),y
	ldx	Source
	cpx	EndProg
	bne	L100	; 2575
	lda	Source+1
	cmp	EndProg+1
	beq	L101	; 25BF
L100	inx
	stx	Source
	bne	L102	; 257C
	inc	Source+1
L102	inc	Dest
	bne	L103	; 2565
	inc	Dest+1
	bne	L103	; 2565
L099	adc	EndProg
	sta	Dest
	sta	Source
	tya
	adc	EndProg+1
	sta	Dest+1
	sta	Source+1
	lda	Source
	sbc	GosubStkPtr
	lda	Source+1
	sbc	GosubStkPtr+1
	bcc	L104	; 25A0
	dec	IlPtr
	jmp	Error	; 2114

L104	lda	(EndProg),y
	sta	(Source),y
	ldx	EndProg
	bne	L105	; 25AA
	dec	EndProg+1
L105	dec	EndProg
	ldx	Source
	bne	L106	; 25B2
	dec	Source+1
L106	dex
	stx	Source
	cpx	Temp1
	bne	L104	; 25A0
	ldx	Source+1
	cpx	Temp1+1
	bne	L104	; 25A0
L101	lda	Dest
	sta	EndProg
	lda	Dest+1
	sta	EndProg+1
L098	lda	LineNumber
	ora	LineNumber+1
	beq	L107	; 25E4
	lda	LineNumber
	sta	(Temp1),y
	iny
	lda	LineNumber+1
	sta	(Temp1),y
L108	iny
	sty	Temp2
	jsr	FetchByte	; 2214
	php
	ldy	Temp2
	sta	(Temp1),y
	plp
	bne	L108	; 25D6
L107	jmp	L053	; 20CC
;
;**********************************************************************
; Divide the top two items on the stack.
;
DoDV	jsr	L146	; 2154
	lda	$03,x
	and	#$80
	beq	L147	; 25F2
	lda	#$FF
L147	sta	Temp1
	sta	Temp1+1
	pha
	adc	$02,x
	sta	$02,x
	pla
	pha
	adc	$03,x
	sta	$03,x
	pla
	eor	$01,x
	sta	$BB
	bpl	L148	; 260B
	jsr	L149	; 2643
L148	ldy	#$11
	lda	$00,x		;divide by zero check?
	ora	$01,x
	bne	L150
	jmp	Error		;divide by zero
L150	sec
	lda	Temp1
	sbc	$00,x
	pha
	lda	Temp1+1
	sbc	$01,x
	pha
	eor	Temp1+1
	bmi	L151	; 262F
	pla
	sta	Temp1+1
	pla
	sta	Temp1
	sec
	jmp	L152	; 2632
;
L151	pla
	pla
	clc
L152	rol	$02,x
	rol	$03,x
	rol	Temp1
	rol	Temp1+1
	dey
	bne	L150	; 2616
	lda	$BB
	bpl	L153	; 264E
;
;**********************************************************************
; Do the NE opcode.  Negate the top item on the stack.
; Clobbers A and X.
;
DoNE	ldx	ExStackPtr
L149	sec
	tya
	sbc	$00,x
	sta	$00,x
	tya
	sbc	$01,x
	sta	$01,x
L153	rts
;
;**********************************************************************
; Tricky and clever re-use of the add logic.  The subtract logic
; negates the top item on the expression stack, then falls into the
; DoAD subroutine which adds the top two items on the stack.
;
DoSU	jsr	DoNE		;make TOS negative
DoAD	jsr	L146		;get index to TOS
	lda	$00,x
	adc	$02,x
	sta	$02,x
	lda	$01,x
	adc	$03,x
	sta	$03,x
	rts
;
;**********************************************************************
; Multiply the top two items on the stack.
;
DoMP	jsr	L146	; 2154
	ldy	#$10
	lda	$02,x
	sta	Temp1
	lda	$03,x
	sta	Temp1+1
L155	asl	$02,x
	rol	$03,x
	rol	Temp1
	rol	Temp1+1
	bcc	L154	; 2686
	clc
	lda	$02,x
	adc	$00,x
	sta	$02,x
	lda	$03,x
	adc	$01,x
	sta	$03,x
L154	dey
	bne	L155	; 266F
	rts
;
;**********************************************************************
; The top byte of the computational stack is used to index into Page 0.
; It is replaced by the two bytes fetched.  Error stops occur with
; stack overflow or underflow.
;
DoFV	jsr	PopExByte	; 2395
	tax
	lda	$00,x
	ldy	$01,x
	dec	ExStackPtr
	ldx	ExStackPtr
	sty	$00,x
	jmp	PushExByte	; 2387
;
;**********************************************************************
; The top two bytes of the computational stack are stored into memory
; at the Page 00 address specified by the third byte on the stack. All
; three bytes are deleted from the stack.  Underflow results in an
; error stop. 
;
DoSV	ldx	#$7D
	jsr	L140	; 2156
	lda	$01,x
	pha
	lda	$00,x
	pha
	jsr	PopExByte	; 2395
	tax
	pla
	sta	$00,x
	pla
	sta	$01,x
	rts
;
;**********************************************************************
; The IL control stack is popped to give the address of the next IL
; instruction. An error stop occurs if the entire control stack (IL and
; BASIC) is empty. 
;
DoRT	jsr	L045	; 26FD
	lda	Temp1
	sta	IlPtr
	lda	Temp1+1
	sta	IlPtr+1
	rts
;
;**********************************************************************
; If BASIC pointer is pointing into the input line buffer, it is copied
; to the Saved Pointer; otherwise the two pointers are exchanged.
;
DoSB	ldx	#$2C
	bne	L161	; 26C3
DoRB	ldx	#Source
L161	lda	$00,x
	cmp	#$80
	bcs	L091	; 26D6
	lda	$01,x
	bne	L091	; 26D6
	lda	LinePtr
	sta	Source
	lda	LinePtr+1
	sta	Source+1
	rts

L091	lda	LinePtr
	ldy	Source
	sty	LinePtr
	sta	Source
	lda	LinePtr+1
	ldy	Source+1
	sty	LinePtr+1
	sta	Source+1
	ldy	#0
	rts
;
;**********************************************************************
; The current BASIC line number is pushed onto the BASIC region of the
; control stack. It is essential that the IL stack be empty for this to
; work properly but no check is made for that condition. An error stop
; occurs on stack overflow.
;
DoGS	lda	LineNumber
	sta	Temp1
	lda	LineNumber+1
	sta	Temp1+1
	jsr	L160	; 219C
L157	lda	GosubStkPtr
	sta	GoStkTop
	lda	GosubStkPtr+1
	sta	GoStkTop+1
L048	rts

L045	lda	(GosubStkPtr),y
	sta	Temp1
	jsr	L046	; 2708
	lda	(GosubStkPtr),y
	sta	Temp1+1
L046	inc	GosubStkPtr
	bne	L047	; 270E
	inc	GosubStkPtr+1
L047	lda	EndUser
	cmp	GosubStkPtr
	lda	EndUser+1
	sbc	GosubStkPtr+1
	bcs	L048	; 26FC
	jmp	Error	; 2114
;
;**********************************************************************
; The top six bytes of the expression stack contain three numbers with
; the following interpretations: The top number is loaded into the A
; (or A and B) register; the next number is loaded into 16 bits of
; Index register; the third number is interpreted as the address of a
; machine language subroutine to be called. These six bytes on the
; expression stack are replaced with the 16-bit result returned by the
; subroutine. Stack underflow results in an error stop.
;
DoUS	jsr	L083	; 2724
	sta	Temp1
	tya
	jmp	L084	; 2382
L083	jsr	DoSP	; 24FC
	lda	Temp1
	sta	Temp2
	jsr	DoSP	; 24FC
	lda	Temp1+1
	sta	Temp2+1
	ldy	Temp1
	jsr	DoSP	; 24FC
	ldx	Temp2+1
	lda	Temp2
	clc
	jmp	($00BC)
;
;**********************************************************************
; This handles the LN opcode.  Push the following 16 bit value onto
; the expression stack.  Pretty tricky... call DoLB to push the first
; byte, then fall into DoLB to do the second!
;
DoLN	jsr	DoLB		;call DoLB to push one byte
;
;**********************************************************************
; LB handler... next byte gets pushed onto the expression stack
;
DoLB	jsr	GetIlByte	;get the byte...
	jmp	PushExByte	;...then push it.
;
; Store X in LinePtr+1, then compare it to 0.  Returns with Z set if
; X is now zero, else Z clear.
;
StxLinePtr
	stx	LinePtr+1
	cpx	#0
	rts
;
;**********************************************************************
; These routines appear to process opcodes that I can't find any
; definition of in the C version of Tiny Basic.
;
L038	ldy	#$02		;start of user program + 2?
L037	sty	Temp1
	ldy	#$29		;start of user program?
	sty	Temp1+1
	ldy	#$00
	lda	(Temp1),y	;pick up first char in program
	cmp	#$08		;see if it's a backspace???
	bne	L116	; 2760	;if not, just exit???
	jmp	ProcJ	; 2168	
L116	rts
;
;**********************************************************************
; Print the character in A, then fall into Padding and send a single
; pad character.
;
L070	jsr	OUTCHAR
;
;**********************************************************************
; Based on the MSB of OutPad, determine whether to send a single
; $FF or a single $00 as pad characters.
;
Padding	lda	#$FF		;assume $ff as the default
	bit	OutPad
	bmi	PadOut		;Yep, use the $ff
	lda	#$00		;else, use $00
PadOut	jmp	OUTCHAR		;print it!
;
;**********************************************************************
; The IL code for TB.  Need to pull the more detailed version off
; Tom's web site, but this works for now.
;
DefaultIL

;
; This was from the original disassembly I got for the 6502 version.
; The IL code on Tom's web page has some minor fixes, so use that
; instead.  This is just here in case we ever need it.
;
	.byte	$24,$3A,$91,$27,$10,$E1,$59,$C5,$2A,$56,$10,$11,$2C,$8B,$4C,$45
	.byte	$D4,$A0,$80,$BD,$30,$BC,$E0,$13,$1D,$94,$47,$CF,$88,$54,$CF,$30
	.byte	$BC,$E0,$10,$11,$16,$80,$53,$55,$C2,$30,$BC,$E0,$14,$16,$90,$50
	.byte	$D2,$83,$49,$4E,$D4,$E5,$71,$88,$BB,$E1,$1D,$8F,$A2,$21,$58,$6F
	.byte	$83,$AC,$22,$55,$83,$BA,$24,$93,$E0,$23,$1D,$30,$BC,$20,$48,$91
	.byte	$49,$C6,$30,$BC,$31,$34,$30,$BC,$84,$54,$48,$45,$CE,$1C,$1D,$38
	.byte	$0D,$9A,$49,$4E,$50,$55,$D4,$A0,$10,$E7,$24,$3F,$20,$91,$27,$E1
	.byte	$59,$81,$AC,$30,$BC,$13,$11,$82,$AC,$4D,$E0,$1D,$89,$52,$45,$54
	.byte	$55,$52,$CE,$E0,$15,$1D,$85,$45,$4E,$C4,$E0,$2D,$98,$4C,$49,$53
	.byte	$D4,$EC,$24,$00,$00,$00,$00,$0A,$80,$1F,$24,$93,$23,$1D,$30,$BC
	.byte	$E1,$50,$80,$AC,$59,$85,$52,$55,$CE,$38,$0A,$86,$43,$4C,$45,$41
	.byte	$D2,$2B,$84,$52,$45,$CD,$1D,$A0,$80,$BD,$38,$14,$85,$AD,$30,$D3
	.byte	$17,$64,$81,$AB,$30,$D3,$85,$AB,$30,$D3,$18,$5A,$85,$AD,$30,$D3
	.byte	$19,$54,$2F,$30,$E2,$85,$AA,$30,$E2,$1A,$5A,$85,$AF,$30,$E2,$1B
	.byte	$54,$2F,$98,$52,$4E,$C4,$0A,$80,$80,$12,$0A,$09,$29,$1A,$0A,$1A
	.byte	$85,$18,$13,$09,$80,$12,$01,$0B,$31,$30,$61,$72,$0B,$04,$02,$03
	.byte	$05,$03,$1B,$1A,$19,$0B,$09,$06,$0A,$00,$00,$1C,$17,$2F,$8F,$55
	.byte	$53,$D2,$80,$A8,$30,$BC,$31,$2A,$31,$2A,$80,$A9,$2E,$2F,$A2,$12
	.byte	$2F,$C1,$2F,$80,$A8,$30,$BC,$80,$A9,$2F,$83,$AC,$38,$BC,$0B,$2F
	.byte	$80,$A8,$52,$2F,$84,$BD,$09,$02,$2F,$8E,$BC,$84,$BD,$09,$93,$2F
	.byte	$84,$BE,$09,$05,$2F,$09,$91,$2F,$80,$BE,$84,$BD,$09,$06,$2F,$84
	.byte	$BC,$09,$95,$2F,$09,$04,$2F,$00,$00,$00

;**********************************************************************
; This is the start of the program area where the user's BASIC program
; gets stored.  
;
codeend	=	*

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R65X1 Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SerSta          = $A000
SerDat          = $A001

; Get a character from the ACIA
; Runs into SNDCHR to provide echo
;
CIN:	LDA SerSta		;GET STATUS FROM ACIA
	AND #$01		;CHECK FOR A CHARACTER
	BEQ CIN			;Loop until we get one
	LDA SerDat		;GET CHARACTER

;
;Send a character to the ACIA
;
COUT:	PHA			;Save the character to be printed
COUT1:	LDA SerSta		;GET ACIA STATUS
	AND #$02
	BEQ COUT1		;IF STILL BUSY GO GET STATUS AGAIN
	PLA			;Restore the character
	AND #$7F		;Strip parity bit
	STA SerDat		;SEND CHARACTER
EXSC	RTS			;Return
