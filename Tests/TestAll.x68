*-----------------------------------------------------------
* Title			: TestAll
* Written by	: DifficultWare
* Date			: 12/5/19
* Description	: File that contains all instructions for our disassembler
*-----------------------------------------------------------
	ORG    $9000

START:                  ; first instruction of program


* SUB, SUBQ, 
* CMP, CMPI, MULS, DIVS `LEA, NEG, 
* OR, ORI, EOR, LSL/R, ASL/R, ROL/R, 
* BCS, BGE, BLT, BVC, BLCR, BRA, JSR, RTS




** SUBQ (PASS) 
 	SUBQ.B 	#2,D1
 	SUBQ.W 	#3,D2
 	SUBQ.L 	#7,D3
 	SUBQ.W  #8,D4
 	SUBQ.W #1,(A1)+

** SUB (PASS)
 	SUB.B 	D1,D2
 	SUB.W 	(A1)+,D3
 	SUB.L 	-(A5),D4
 ;	SUB.W   #$0020,D1   -- IGNORE! (SUBI)
 	SUB.L 	(A2),D0
 ;	SUB.B 	#$87,D2     -- IGNORE! (SUBI)


**JSR/RTS (PASS)
*    JSR		Test_Branch

** MULS (PASS)
    MULS    #4,D2
 	MULS    D7,D6
	MULS	D2,D3
	MULS	(A2)+,D5
	MULS 	-(A7),D3
	MULS	#$1111,D5
	MULS	D1,D2
*
*
* DIVS (PASS)
    DIVS    #4,D2
    MOVE.B  #1,D2    ; TO AVOID DIVISION BY 0
	 DIVS	D2,D3
	 MOVE.B  #1,(A2)
	 DIVS	(A2)+,D5
	 MOVE.B  #1,(A7)
	 DIVS 	-(A7),D3
	 DIVS	#$1111,D5
	 MOVE.B  #1,D1
	 DIVS	D1,D2	
*
* LEA (PASS)
    LEA		$123456, A1
	LEA		(A2),A4
	LEA		$412,A0



** NEG (PASS)
    NEG.B   D5
    NEG.W   D2
    NEG.L   D6

    NEG.B   (A4)
    NEG.W   (A2)+
    NEG.L   -(A0)

    NEG.B   D1
    NEG.W   D2
    NEG.L   D6
    NEG.B   D5
    NEG.W   D2
    NEG.L   D6

** OR (PASS) -- Did this include both ea-dn / dn-ea?
	OR	D1,D2
	OR	D3,D4
	OR	#12,D5
	OR	#$1234,D6
	OR	#$6544,D6       ; imm data can't be long ..? (OR P.254)
	MOVE.L 	#$765433,D0
	MOVE.L 	#$765433,(A1)
	OR.B	D0,D6
	OR.W	D6,D0
	OR.L	(A1),D6
	OR	(A1)+,D6
	OR	-(A1),D6

* ORI (PASS)
    ORI.B #1,D2
    ORI.B #20,D3
    ORI.B #$11,(A0)
    ORI.B #$22,(A0)+
    ORI.B #$BA,-(A0)
    
    ORI.W #$123,D2
    ORI.W #203,D3
    ORI.W #$111,(A0)
    ORI.W #$222,(A0)+
    ORI.W #$BAC,-(A0)
    
    ORI.L #$12345,D2
    ORI.L #2034332,D3
    ORI.L #$111111,(A0)
    ORI.L #$2222222,(A0)+
    ORI.L #$BACDE122,-(A0)


* BCLR (PASS) -- NEED MORE CASES?
    BCLR    D3,D5
    BCLR    #3,D2
    BCLR    #23,D7 ; #23 = #$17 

* LSL/R  -- (PASS)
    LSL.B   #8,D7
    LSL.B   #2,D1
    LSL.W   #3,D0
    LSL.W   #8,D0
    LSL.L   #8,D2
    
    LSL.B   D1,D7
    LSL.W   D3,D2
    LSL.L   D5,D3

    LSR.B   #2,D7
    LSR.B   #8,D7
    LSR.W   #1,D0
    LSR.W   #8,D0
    LSR.L   #8,D2
    
    LSR.B   D1,D7
    LSR.W   D3,D2
    LSR.L   D5,D3
 
* ASL/R -- (PASS)
    ASL.B   #8,D7
    ASL.B   #2,D1
    ASL.W   #3,D0
    ASL.W   #8,D0
    ASL.L   #8,D2
    
    ASL.B   D1,D7
    ASL.W   D3,D2
    ASL.L   D5,D3
    
    ASR.B   #2,D7
    ASR.B   #8,D7
    ASR.W   #1,D0
    ASR.W   #8,D0
    ASR.L   #8,D2
    
    ASR.B   D1,D7
    ASR.W   D3,D2
    ASR.L   D5,D3

* ROL/R -- (PASS)
    ROL.B   #8,D7
    ROL.B   #2,D1
    ROL.W   #3,D0
    ROL.W   #8,D0
    ROL.L   #8,D2
    
    ROL.B   D1,D7
    ROL.W   D3,D2
    ROL.L   D5,D3
    
    ROR.B   #2,D7
    ROR.B   #8,D7
    ROR.W   #1,D0
    ROR.W   #8,D0
    ROR.L   #8,D2
    
    ROR.B   D1,D7
    ROR.W   D3,D2
    ROR.L   D5,D3


* EOR (PASS : do not pass imm value)
    EOR.B     D1,D2
    EOR.B     D3,(A0)
    EOR.B     D5,(A1)+
    EOR.B     D7,-(A1)  
    
    MOVE.W    #$6544,D5
    EOR.W     D5,D1
    EOR.W     D5,(A2)
    EOR.W     D5,(A2)+
    EOR.W     D5,-(A2)
    
    MOVE.L    #$654EF4,D1
    EOR.L     D5,D1
    EOR.L     D5,(A2)
    EOR.L     D5,(A2)+
    EOR.L     D5,-(A2)

    
* CMPI (Pass)
 	CMP.W D1,D2
 	CMPI.L #$11111111,D2
 	CMPI.W #$1111,D2
 	CMPI.B #$1,D2


*Test_Branch:
*	RTS

*moveTest
	MOVE.B 	D0,D1	* incorrect - not even printed
	
	MOVE.W	A0,D1
	
	MOVE.B	(A0),D1
	MOVE.B	D0,(A0)
	
	MOVE.B	-(A0),D1
	MOVE.B	D0,-(A0)
	
	MOVE.B	(A7)+,D1
	MOVE.B	D0,(A7)+
	
	MOVE.W 	$1234,D1
	MOVE.W	D1,$1234
	
	MOVE.L 	$12345678,D1

	MOVE.L	D1,$12345678

	MOVE.B 	#10,D1



*moveaTest:	
    MOVEA.W	D0,A1	* incorrect - not printed
	MOVEA.W	A0,A1

	MOVEA.L		(A0),A1	
    MOVEA.L		-(A0),A1
	MOVEA.L		(A2)+,A1	
    MOVEA.W	$1234,A1
	MOVEA.L		$12345678,A1	
    MOVEA.L		#20,A1

*movemTest
movemToSave		REG		A0/A3/A6/D0-D7
 	MOVEM.W 	movemToSave,(A7)
 	MOVEM.L 	movemToSave,-(A7)
 	MOVEM.W 	movemToSave,$1234
 	MOVEM.L 	movemToSave,$12345678
 	 
 	 MOVEM.W 	(A7),movemToSave
 	 MOVEM.L 	(A7)+,movemToSave
	 MOVEM.W 	$1234,movemToSave
	 MOVEM.L 	$12345678,movemToSave

*addTest
	ADD.B 	D0,D1
	ADD.W 	A0,D1
	ADD.L	(A0),D1
	ADD.B 	-(A0),D1
	ADD.W 	(A0)+,D1
	ADD.W	$1234,D1
	ADD.L	$12345678,D1
	* ADD.L 	#55,D1	* converts to ADDI (unsupported) - expected

	ADD.B	D0,(A0)
	ADD.W	D0,-(A0)
	ADD.L	D0,(A0)+
	ADD.W	D0,$1234
	ADD.L	D0,$12345678

*addaTest
	ADDA.W	D0,A1
	ADDA.W	A0,A1
	ADDA.L	(A0),A1
	ADDA.L	-(A0),A1
	ADDA.W	(A0)+,A1
	ADDA.W	$1234,A1

	ADDA.L	$12345678,A1
	ADDA.L	#8888,A1

*cmpTest:
	CMP.B	D0,D1
	CMP.W	A0,D1
	CMP.W	(A0),D1
	CMP.W 	-(A1),D1
	CMP.W 	(A3)+,D1
	CMP.W	$0055,D1
	CMP.L	$00550055,D1
	CMP.B 	#23,D1

bccTest:
prevBcc:
	NOP

	BCS		prevBcc
	BCS		postBcc
	BGE 	prevBcc
	BGE 	postBcc
	BLT		prevBcc
	BLT		postBcc
	BVC		prevBcc
	BVC		postBcc
	
postBcc:
	NOP
	
	RTS

braTest:
	BRA		prevBcc
	BRA		postBcc
	
	RTS

done:
	SIMHALT




* addrPntr		DC.L		$0

* 	ORG		$9200* braTest2Mthd:
* 	BRA		braTestsDone

	END    START        ; last line of source
















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
