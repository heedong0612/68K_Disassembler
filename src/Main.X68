*--------------------------------------------------------------------------
* Title      : Disassembler Skeleton 
* Written by : Ryan, Donghee, Anwar
* Date       : 
* 
* Description: This code contains a method for you to use
* with your Disassembler project IO, and a short demo of 
* how to call this method in the body of the "START" code.
* 
* Hints and Tips:
*   -Follow the code commenting convention here for file & method headers
*   -Don't rename this file name (Main.X68)
*   -Don't reorg the start address ($1000)
*   -Don't rename or edit the IO method I've provided you with here
*   -Don't rename the config.cfg file or change the file format: 
*    <Long_StartAddress>\CR\LF
*    <Long_EndAddress>\CR\LF<EOF>
*---------------------------------------------------------------------------
    ORG    $1000    *Don't change this; see hints and tips above
*---------------------------------------------------------------------------
START:
    ***********************************************************
    * Code demo for printing strings to console & file is here
    * Pay close attention to:
    *   (1) the detailed comments, 
    *   (2) how to build a (Callee-Saved) method
    *   (3) how to call that method using JSR (return with RTS)
    ***********************************************************
    * LEA MSG1, A1        ; buffer of chars to write
    * JSR TrapTask13
    
    * LEA MSG2, A1        ; buffer of chars to write    
    * JSR TrapTask13

    * LEA ascii_val, A1
    * JSR AsciiToHex     ;  example of how to convert ascii to hex

    **************************************************
    *Your disassembler code goes here
    **************************************************
    
    ;Open config.cfg (trap subtasks 50-59) (this is an IO responsibility if 3 team members)
    ;load start and end address as longs
    
    		LEA			stackStart,A7		* stack setup
    
    		MOVE.B		#50,D0			* close all files (recommended)
    		TRAP		#15
    		
		LEA			inFilename,A1		* open the file with the starting and ending addresses
    		MOVE.B		#51,D0
    		TRAP		#15
    		
		JSR			addrFromFile
		MOVEA.L		D7,A0			* load the starting address
		JSR			addrFromFile
		MOVEA.L		D7,A1			* load the ending address
   
    ;loop from start to end, printing out the instruction or DATA if not recognized 
    ;   use my method below (printStringToFileAndConsole) to print out the individual instruction (or DATA)

LOOP:
	JSR			printMemAddr	* print the current memory address

	JSR			determineOp	* determine the op code in D0 here
	
	MOVE.L		A1,-(A7)
	LEA			NEWLINE,A1	* print a newline
	JSR			TrapTask13
	MOVE.L		(A7)+,A1

	ADDQ.W		#2,A0		* point the address at the next byte to read
	CMPA.L		A0,A1		 * compare the starting address to the ending address
	BGT			LOOP		* continue to loop if the starting address is before the ending address

    SIMHALT

*********************************************************************************
* Method Name:	addrFromFile
* Description:		 reads a line from the config file and stores it in D7; LINE MUST BE IN THE CONFIG FILE FORMAT
*
* Preconditions:		D1.L - file ID
* Postconditions:	D7 - the address in the file
*********************************************************************************
addrFromFileToSave REG D0-D2/A1
addrFromFile:
	MOVEM.L		addrFromFileToSave,-(A7)		* store registers on the stack

	LEA			addrBuff,A1		* load the buffer to read into
    	MOVE.W		#10,D2			* read 10 bytes into the buffer
    	MOVE.B		#53,D0			* read from the file descriptor in D1
    	TRAP		#15
    	
    	JSR			AsciiToHex		* convert the hex value to ascii

	MOVEM.L		(A7)+,addrFromFileToSave	* restore registers on the stack
	RTS

*********************************************************************************
* Method Name:	determineOp
* Description:		determines the op code for the given 
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
determineOp:
	MOVEM.L		A0-A6/D0-D7,-(A7)	* copy registers to stack

	MOVE.W		(A0),D0		* copy the value at the address
	MOVE.W		D0,D1		; store to D1 
	AND.W		#$F000,D1	; and overwrite on D1
    
	CMP.W	#$0000,D1   ; compare the first bit  (0)
	BEQ		group0

	CMP.W	#$1000,D1	; compare the first bit  (1)
	BEQ		group1	; Byte (MOVE only)

	CMP.W	#$2000,D1	; compare the first bit  (1)
	BEQ		group2	; Long (MOVE or MOVEA)

	CMP.W	#$3000,D1	; compare the first bit  (1)
	BEQ		group3	; Word (MOVE or MOVEA)

	CMP.W	#$4000,D1   ; compare the first bit  (4)	
	BEQ		group4

	CMP.W	#$5000,D1   ; compare the first bit  (5)
	BEQ		group5

	CMP.W	#$6000,D1   ; compare the first bit  (6)
	BEQ		group6
	
	CMP.W	#$8000,D1   ; compare the first bit  (8)
	BEQ		group8

	CMP.W	#$9000,D1   ; compare the first bit  (9)
	BEQ		group9

	CMP.W	#$B000,D1   ; compare the first bit  (B)
	BEQ		groupB

	CMP.W	#$C000,D1   ; compare the first bit  (C)
	BEQ		groupC

	CMP.W	#$D000,D1   ; compare the first bit  (D)
	BEQ		groupD

	CMP.W	#$E000,D1   ; compare the first bit  (E)
	BEQ		groupE
    
	BRA		groupDATA	*DATA
    
doneOp:
	MOVEM.L		(A7)+,A0-A6/D0-D7	* restore registers from stack
	RTS

*********************************************************************************
* Method Name: 	group0
* Description: 		handles op codes starting with 0x0
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group0:
	
	* BCLR
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$FFC0,D0	* store bitmask result in D0
	
	CMP.W	#$0880,D0	* compare D0 value to known BCLR bits
	BEQ	bclrCmd		* handle a BCLR command

	* CMPI
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$FF00,D0	* store bitmask result in D0
	CMP.W	#$0C00,D0	* compare D0 value to known CMPI bits	
	BEQ	cmpiCmd		* handle a CMPI command
	
  *ORI.B
	MOVE.W  (A0),D0     * redundant? 
	AND.W   #$FFC0,D0   * store bitmast result in D0
	CMP.W   #$0000,D0   * compare D0 value to known ORI bits
	BEQ     oriBCmd      * handle a ORI command
	
  *ORI.W
	CMP.W   #$0040,D0   * compare D0 value to known ORI bits
	BEQ     oriWCmd      * handle a ORI command

  *ORI.L
	CMP.W   #$0080,D0   * compare D0 value to known ORI bits
	BEQ     oriLCmd      * handle a ORI command


	
	BRA		groupDATA	* no match found so go to group DATA       

*********************************************************************************
* Method Name: 	group1
* Description: 		handles op codes starting with 0x1
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group1:
	* MOVE.B
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F000,D0	* store bitmask result in D0
	CMP.W	#$1000,D0	* compare D0 value to known MOVE.B bits
	BEQ	moveBCmd	* handle a MOVE.B command
	
	BRA	groupDATA	* no match found so go to group DATA

*********************************************************************************
* Method Name: 	group2
* Description: 		handles op codes starting with 0x2
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group2:
	* MOVEA.W
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F1C0,D0	* store bitmask result in D0
	CMP.W	#$21C0,D0	* compare D0 value to known MOVEA.W bits
	BEQ	moveaWCmd	* handle a MOVEA.W command

	* MOVE.W
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F000,D0	* store bitmask result in D0
	CMP.W	#$2000,D0	* compare D0 value to known MOVE.B bits
	BEQ	moveWCmd	* handle a MOVE.B command
	
	BRA	groupDATA	* no match found so go to group DATA

*********************************************************************************
* Method Name: 	group3
* Description: 		handles op codes starting with 0x3
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group3:
	
	* MOVEA.L
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F1C0,D0	* store bitmask result in D0
	CMP.W	#$31C0,D0	* compare D0 value to known MOVEA.L bits
	BEQ	moveaLCmd	* handle a MOVEA.L command

	* MOVE.L
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F000,D0	* store bitmask result in D0
	CMP.W	#$3000,D0	* compare D0 value to known MOVE.L bits
	BEQ	moveLCmd	* handle a MOVE.L command
	
	BRA	groupDATA	* no match found so go to group DATA

*********************************************************************************
* Method Name: 	group4
* Description: 		handles op codes starting with 0x4 
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group4:

	* RTS
	CMP.W	#$4E75,(A0) * compare to the RTS bits
	BEQ		rtsCmd		* handle an RTS command

	* JSR
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$FFC0,D0	* store bitmask result in D0
	CMP.W	#$4E80,D0	* compare D0 value to known JSR bits
	BEQ	jsrCmd		* handle a JSR command

	* MOVEM
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$FC80,D0	* store bitmask result in D0
	CMP.W	#$4880,D0	* compare D0 value to known MOVEM bits
	BEQ	movemRegCmd	* handle a MOVEM command (reg->mem)

	CMP.W	#$4C80,D0	* compare D0 value to known JSR bits
	BEQ	movemMemCmd	* handle a MOVEM command (mem->reg)

    * LEA
	MOVE.W	(A0),D0		* redundant?
	AND.W	#$F1C0,D0	* store bitmask result in D0
	CMP.W	#$41C0,D0	* compare D0 value to known LEA bits
	BEQ		leaCmd		* handle a LEA command
    
    * NEG.B
	MOVE.W	(A0),D0		* redundant?
	AND.W	#$FFC0,D0	* store bitmask result in D0
	CMP.W	#$4400,D0	* compare D0 value to known NEG bits
	BEQ		negBCmd		* handle a NEG command
	
	* NEG.W
	CMP.W	#$4410,D0	* compare D0 value to known NEG bits
	BEQ		negWCmd		* handle a NEG command

    * NEG.L
	CMP.W	#$4480,D0	* compare D0 value to known NEG bits
	BEQ		negLCmd		* handle a NEG command


	* DATA
	BRA		groupDATA
	* no match found so go to group DATA

*********************************************************************************
* Method Name: 	group5
* Description: 		handles op codes starting with 0x5
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group5:
	LEA  strGroup5, A1
	MOVE.B  #14, D0		
	TRAP    #15
	
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F1C0,D0		* store bitmask result in D0
	
	* SUBQ
	CMP.W	#$5100,D0	* compare D0 value to known SUBQ.B bits
	BEQ	subqBCmd	* handle a SUBQ.B command 
	
	CMP.W	#$5140,D0	* compare D0 value to known SUBQ.W bits
	BEQ	subqWCmd	* handle a SUBQ.W command 
	
	CMP.W	#$5180,D0	* compare D0 value to known SUBQ.L bits
	BEQ	subqLCmd	* handle a SUBQ.L command 
		
    BRA		doneOp
    
*********************************************************************************
* Method Name: 	group6
* Description: 		handles op codes starting with 0x6
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group6:
	
	* Bcc
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$FF00,D0	* store bitmask result in D0
	* BRA
	CMP.W	#$6000,D0	* compare D0 value to known BRA bits
	BEQ	braCmd		* handle a BRA command
	* BCS
	CMP.W	#$6500,D0	* compare D0 value to known BCS bits
	BEQ	bcsCmd		* handle a BCS command
	* BGE
	CMP.W	#$6C00,D0	* compare D0 value to known BGE bits
	BEQ	bgeCmd		* handle a BGE command
	* BLT
	CMP.W	#$6D00,D0	* compare D0 value to known BLT bits
	BEQ	bltCmd		* handle a BLT command
	* BVC
	CMP.W	#$6900,D0	* compare D0 value to known BVC bits
	BEQ	bvcCmd		* handle a BVC command

	* DATA
	BRA	groupDATA	* no match found so go to group DATA

*********************************************************************************
* Method Name: 	group8
* Description: 		handles op codes starting with 0x8
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group8:
	
	*DIVS
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F1C0,D0	* store bitmask result in D0
	
	CMP.W	#$81C0,D0	* compare D0 value to known DIVS bits
	BEQ		divsCmd		* handle a DIVS command
	
    *OR -- make sure that this one comes last!!
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F000,D0	* store bitmask result in D0
	
	CMP.W	#$8000,D0	* compare D0 value to known OR bits
	BEQ		orCmd		* handle a OR command
	
	BRA doneOp
    
*********************************************************************************
* Method Name: 	group9
* Description: 		handles op codes starting with 0x9
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
group9:
	LEA  strGroup9, A1
	MOVE.B  #14, D0
	TRAP    #15
	
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F1C0,D0	* store bitmask result in D0
	
	* SUB.B (000, 100)
	CMP.W	#$9000,D0	* compare D0 value to known SUB.B bits
	BEQ 	subBdnCmd	* handle a SUB.B command (dn - ea)
	
	CMP.W	#$9100,D0	* compare D0 value to known SUB.B bits
	BEQ	subBeaCmd	* handle a SUB.B command (ea - dn)
	
	* SUB.W
	CMP.W	#$9040,D0	* compare D0 value to known SUB.W bits
	BEQ	subWdnCmd	* handle a SUB.B command (dn - ea)
	
	CMP.W	#$9140,D0	* compare D0 value to known SUB.W bits
	BEQ	subWeaCmd	* handle a SUB.B command (ea - dn)
	
	* SUB.L
	CMP.W	#$9080,D0	* compare D0 value to known SUB.L bits
	BEQ	subLdnCmd	* handle a SUB.B command (dn - ea)
	
	CMP.W	#$9180,D0	* compare D0 value to known SUB.L bits
	BEQ	subLeaCmd	* handle a SUB.B command (ea - dn)
	
	BRA doneOp
    
*********************************************************************************
* Method Name: 	groupB
* Description: 		handles op codes starting with 0xB
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
groupB:

	LEA  strGroupB, A1
	MOVE.B  #14, D0
	TRAP    #15

	* CMP
  MOVE.W	(A0),D0		* store op code value
	AND.W	#$F000,D0	* store bitmask result in D0
	CMP.W 	#$B000,D0	* compare D0 value to known CMP bits	
	BEQ	cmpCmd		* handle a CMP command
	
  * EOR
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F100,D0	* store bitmask result in D0
	CMP.W	#$B100,D0	* compare D0 value to known EOR bits
	BEQ		eorCmd		* handle a EOR command

	BRA doneOp
    
*********************************************************************************
* Method Name: 	groupC
* Description: 		handles op codes starting with 0xC
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
groupC:

    * MULS
    MOVE.W  (A0),D0         * store op code value
    AND.W   #$F1C0, D0      * store bitmask result in D0

    CMP.W   #$C1C0, D0      * compare D0 value to known MULS bits
    BEQ     mulsCmd         * handle a muls command
    
    BRA doneOp
    

*******************************************************************************
* Method Name: 	groupD* Description: 		handles op codes starting with 0xD
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
groupD:
	LEA  strGroupD, A1
	MOVE.B  #14, D0
	TRAP    #15

	*ADDA.W
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F0C0,D0	* store bitmask result in D0
	CMP.W	#$D0C0,D0	* compare D0 value to known ADDA.W bits (opmode 011)	
	BEQ	addaWCmd	* handle a ADDA.W command

	*ADDA.L
	MOVE.W	(A0),D0		* store op code value
	AND.W	#$F1C0,D0	* store bitmask result in D0
	CMP.W	#$D1C0,D0	* compare D0 value to known ADDA.W bits (opmode 011)	
	BEQ	addaLCmd	* handle a ADDA.L command

	*ADD.B
	MOVE.W	(A0),D0		* store op code value
	CMP.W	#$D000,D0	* compare D0 value to known ADD.B bits (opmode 000)
	BEQ	addBeaCmd	* handle a ADD.B command (ea+dn)

	CMP.W	#$D100,D0	* compare D0 value to known ADD.B bits (opmode 100)
	BEQ	addBdnCmd	* handle a ADD.B command (dn+ea)

	*ADD.W
	CMP.W	#$D040,D0	* compare D0 value to known ADD.W bits (opmode 001)
	BEQ	addWeaCmd	* handle a ADD.W command (ea+dn)

	CMP.W	#$D140,D0	* compare D0 value to known ADD.W bits (opmode 101)
	BEQ	addWdnCmd	* handle a ADD.W command (dn+ea)

	*ADD.L
	CMP.W	#$D080,D0	* compare D0 value to known ADD.L bits (opmode 010)
	BEQ	addLeaCmd	* handle a ADD.L command (ea+dn)

	CMP.W	#$D180,D0	* compare D0 value to known ADD.L bits (opmode 110)
	BEQ	addLdnCmd	* handle a ADD.L command (dn+ea)

	BRA doneOp
    
*********************************************************************************
* Method Name: 	groupE
* Description: 		handles op codes starting with 0xE
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
groupE:

   * LSL.B
    MOVE.W  (A0),D0         * store op code value
    AND.W   #$F1D8, D0      * store bitmask result in D0

    CMP.W   #$E108, D0      * compare D0 value to known LSL bits
    BEQ     lslBCmd          * handle a LSL command
    
    * LSL.W
    CMP.W   #$E148, D0      * compare D0 value to known LSL bits
    BEQ     lslWCmd          * handle a LSL command
    
    * LSL.L
    CMP.W   #$E188, D0      * compare D0 value to known LSL bits
    BEQ     lslLCmd          * handle a LSL command
    
    *LSR.B
    CMP.W   #$E008, D0      * compare D0 value to known LSR bits
    BEQ     lsrBCmd          * handle a LSR command
    
    *LSR.W
    CMP.W   #$E048, D0      * compare D0 value to known LSR bits
    BEQ     lsrWCmd          * handle a LSR command
    
    *LSR.L
    CMP.W   #$E088, D0      * compare D0 value to known LSR bits
    BEQ     lsrLCmd          * handle a LSR command

    *ASL
    MOVE.W  (A0),D0         * store op code value
    AND.W   #$FFC0, D0      * store bitmask result in D0

    CMP.W   #$E1C0, D0      * compare D0 value to known ASL bits
    BEQ     aslCmd          * handle a ASL command
    
    *ASR
    MOVE.W  (A0),D0         * store op code value
    AND.W   #$FFC0, D0      * store bitmask result in D0

    CMP.W   #$E0C0, D0      * compare D0 value to known ASR bits
    BEQ     asrCmd          * handle a ASR command
    
    * ROL.B
    MOVE.W  (A0),D0         * store op code value
    AND.W   #$F1D8, D0      * store bitmask result in D0

    CMP.W   #$E118, D0      * compare D0 value to known ROL bits
    BEQ     rolBCmd          * handle a ROL.B command
    
    * ROL.W
    CMP.W   #$E158, D0      * compare D0 value to known ROL bits
    BEQ     rolWCmd          * handle a ROL.W command
    
    * ROL.L
    CMP.W   #$E198, D0      * compare D0 value to known ROL bits
    BEQ     rolLCmd          * handle a ROL.L command

    * ROR.B
    CMP.W   #$E018, D0      * compare D0 value to known ROR bits
    BEQ     rorBCmd          * handle a ROR command
    
    * ROR.W
    CMP.W   #$E058, D0      * compare D0 value to known ROR bits
    BEQ     rorWCmd          * handle a ROR command
    
    * ROR.L
    CMP.W   #$E098, D0      * compare D0 value to known ROR bits
    BEQ     rorLCmd          * handle a ROR command

	BRA doneOp
    
*********************************************************************************
* Method Name: 	groupData
* Description: 		the default op code if no matches are found
*
* Preconditions:		A0 - the address of the value to analyze
* Postconditions: 
*********************************************************************************
groupDATA:
	LEA		dataMsg,A1
	MOVE.B	#14, D0
	TRAP	#15
	
	BRA		doneOp
    
*********************************************************************************
* Method Name:	cmpiCmd
* Description:		handles a CMPI command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
cmpiCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		cmpiMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	addaWCmd
* Description:		handles a ADDA.W command	
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addaWCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addaWMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	addaLCmd
* Description:		handles a ADDA.L command	
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addaLCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addaLMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	addBdnCmd
* Description:		handles a ADD.B command	(dn+ea)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addBdnCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addBdnMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	addWdnCmd
* Description:		handles a ADD.W command	(dn+ea)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addWdnCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addWdnMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	addLdnCmd
* Description:		handles a ADD.L command	(dn+ea)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addLdnCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addLdnMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	addBeaCmd
* Description:		handles a ADD.B command	(ea+dn)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addBeaCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addBeaMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	addWeaCmd
* Description:		handles a ADD.W command	(ea+dn)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addWeaCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addWeaMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	addLeaCmd
* Description:		handles a ADD.L command	(ea+dn)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
addLeaCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		addLeaMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	subqBCmd
* Description:		handles a SUBQ.B command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subqBCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subqBMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	subqWCmd
* Description:		handles a SUBQ.W command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subqWCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subqWMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	subqLCmd
* Description:		handles a SUBQ.L command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subqLCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subqLMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	subBdnCmd
* Description:		handles a SUB.B command	(dn-ea)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subBdnCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subBdnMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	subWdnCmd
* Description:		handles a SUB.W command	(dn-ea)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subWdnCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subWdnMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	subLdnCmd
* Description:		handles a SUB.L command	(dn-ea)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subLdnCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subLdnMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	subBeaCmd
* Description:		handles a SUB.B command	(ea-dn)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subBeaCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subBeaMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	subWeaCmd
* Description:		handles a SUB.W command	(ea-dn)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subWeaCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subWeaMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	subLeaCmd
* Description:		handles a SUB.B command	(ea-dn)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
subLeaCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		subLeaMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	
* Description:		handles a CMP command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
cmpCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		cmpMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	movemMemCmd
* Description:		handles a MOVEM.W command	(mem->reg)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
movemMemCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		movemMemMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	movemRegCmd
* Description:		handles a MOVEM.W command	(reg->mem)
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
movemRegCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		movemRegMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	moveaWCmd
* Description:		handles a MOVEA.W command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
moveaWCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		moveaWMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
	
*********************************************************************************
* Method Name:	moveaLCmd
* Description:		handles a MOVEA.L command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
moveaLCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		moveaLMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	moveBCmd
* Description:		handles a MOVE.B command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
moveBCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		moveBMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	moveWCmd
* Description:		handles a MOVE.W command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
moveWCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		moveWMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp

*********************************************************************************
* Method Name:	moveLCmd
* Description:		handles a MOVE.L command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
moveLCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		moveLMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp


*********************************************************************************
* Method Name:	rtsCmd
* Description:		handles an RTS command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
rtsCmd:
	MOVEM.L		A1,-(A7)	* store register to stack

	LEA		rtsMsg,A1
	JSR		TrapTask13	


	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA		doneOp
        
*********************************************************************************
* Method Name:	jsrCmd
* Description:		handles a JSR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
jsrCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		jsrMsg,A1
	JSR		TrapTask13

	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA			doneOp
        
*********************************************************************************
* Method Name:	braCmd
* Description:		handles a BRA command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
braCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		braMsg,A1
	JSR		TrapTask13
	
	MOVEM.L		(A7)+,A1	* restore register from stack
        	BRA doneOp
        	
*********************************************************************************
* Method Name:	bcsCmd
* Description:		handles a BCS command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
bcsCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		bcsMsg,A1
	JSR		TrapTask13
	
	MOVEM.L		(A7)+,A1	* restore register from stack
        	BRA doneOp
        	
*********************************************************************************
* Method Name:	bgeCmd
* Description:		handles a BGE command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
bgeCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		bgeMsg,A1
	JSR		TrapTask13
	
	MOVEM.L		(A7)+,A1	* restore register from stack
        	BRA doneOp
        	
*********************************************************************************
* Method Name:	bltCmd
* Description:		handles a BLT command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
bltCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		bltMsg,A1
	JSR		TrapTask13
	
	MOVEM.L		(A7)+,A1	* restore register from stack
        	BRA doneOp
        	
*********************************************************************************
* Method Name:	bvcCmd
* Description:		handles a BVC command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
bvcCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		bvcMsg,A1
	JSR		TrapTask13
	
	MOVEM.L		(A7)+,A1	* restore register from stack
        	BRA doneOp
        	
*********************************************************************************
* Method Name:	bclrCmd
* Description:		handles a BCLR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
bclrCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		bclrMsg,A1
	JSR		TrapTask13
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	mulsCmd
* Description:		handles a MULS command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
mulsCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	LEA		mulsMsg,A1
	JSR		TrapTask13

    * first bitmask - 0000 0000 0011 1000 - result: 0-7 in D1
    MOVE.W      (A0),D1     * copy address to D0 - 1100 DDD1 11MM MXXX
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask - 0000 0000 000 0111 - result: 0-7 in D2
    MOVE.W      (A0),D2     * copy address to D0 - 1100 DDD1 11MM MXXX
    AND.W       #$0007,D2   * store register of effective address
	
	* third bitmask - 0000 1110 0000 0000 - result: 0-7 in D0
	MOVE.W      (A0),D0     * copy address to D0 - 1100 DDD1 11MM MXXX    
    AND.W       #$0E00,D0   * store destination data register
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
        

*********************************************************************************
* Method Name:	divsCmd
* Description:		handles a DIVS command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
divsCmd:
    * 1000 DDD1 11MM MXXX
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		divsMsg,A1
	JSR		TrapTask13

    * first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0 
    AND.W       #$0007,D2   * store register of effective address
	
	* third bitmask for destination in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0E00,D0   * store destination data register
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp


*********************************************************************************
* Method Name:	leaCmd
* Description:		handles a LEA command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
leaCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		leaMsg,A1
	JSR		TrapTask13
	
	
	* first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0 
    AND.W       #$0007,D2   * store register of effective address
	
	* third bitmask for destination in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0E00,D0   * store destination address register
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	negBCmd
* Description:		handles a NEG command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
negBCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		negBMsg,A1
	JSR		TrapTask13
    
    * first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	negWCmd
* Description:		handles a NEG command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
negWCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		negWMsg,A1
	JSR		TrapTask13
	
	* first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp

*********************************************************************************
* Method Name:	negLCmd
* Description:		handles a NEG command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
negLCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		negLMsg,A1
	JSR		TrapTask13
	
	* first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	orCmd
* Description:		handles a OR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
orCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		orMsg,A1
	JSR		TrapTask13
	
    * first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address
	
	* third bitmask for destination in D0
	MOVE.W      (A0),D0     * copy address to D0    
    AND.W       #$0E00,D0   * store destination address register

    * fourth bitmask for opmode in D3 -- CHECK: D3 ok?
    MOVE.W      (A0),D3     * copy address to D3
    AND.W       #$01C0,D3   * store opmode
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp	

*********************************************************************************
* Method Name:	oriBCmd
* Description:		handles a ORI command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
oriBCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		oriBMsg,A1
	JSR		TrapTask13
	
	    * first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	oriWCmd
* Description:		handles a ORI command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
oriWCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		oriWMsg,A1
	JSR		TrapTask13
	
	    * first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp

*********************************************************************************
* Method Name:	oriLCmd
* Description:		handles a ORI command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
oriLCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		oriLMsg,A1
	JSR		TrapTask13
	
    * first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	eorCmd
* Description:		handles a EOR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
eorCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		eorMsg,A1
	JSR		TrapTask13
	
	    * first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0 
    AND.W       #$0007,D2   * store register of effective address
	
	* third bitmask for destination in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0E00,D0   * store destination data register

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp	

*********************************************************************************
* Method Name:	lslBCmd
* Description:		handles a LSL command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
lslBCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		lslBMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted
	
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	lslWCmd
* Description:		handles a LSL command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
lslWCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		lslWMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted
    
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	lslLCmd
* Description:		handles a LSL command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
lslLCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		lslLMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted
    
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp

*********************************************************************************
* Method Name:	lsrBCmd
* Description:		handles a LSR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
lsrBCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		lsrBMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted
    
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp

*********************************************************************************
* Method Name:	lsrWCmd
* Description:		handles a LSR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
lsrWCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		lsrWMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	lsrLCmd
* Description:		handles a LSR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
lsrLCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		lsrLMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted
	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	aslCmd
* Description:		handles a ASL command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
aslCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		aslMsg,A1
	JSR		TrapTask13
	
	* first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
	
*********************************************************************************
* Method Name:	asrCmd
* Description:		handles a ASR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
asrCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		asrMsg,A1
	JSR		TrapTask13
	
	* first bitmask for mode saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0038,D1   * store mode of effective address
    
    * second bitmask for register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0007,D2   * store register of effective address

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	rolBCmd
* Description:		handles a ROL command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
rolBCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		rolBMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp

*********************************************************************************
* Method Name:	rolWCmd
* Description:		handles a ROL command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
rolWCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		rolWMsg,A1
	JSR		TrapTask13
	
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	rolLCmd
* Description:		handles a ROL command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
rolLCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		rolLMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
		
	
*********************************************************************************
* Method Name:	rorBCmd
* Description:		handles a ROR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
rorBCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		rorBMsg,A1
	JSR		TrapTask13

    	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp

*********************************************************************************
* Method Name:	rorWCmd
* Description:		handles a ROR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
rorWCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		rorWMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name:	rorLCmd
* Description:		handles a ROR command
*
* Preconditions:		A0 - contains the address of the command
* Postconditions:	
*********************************************************************************
rorLCmd:
	MOVEM.L		A1,-(A7)	* store register on stack
	
	LEA		rorLMsg,A1
	JSR		TrapTask13
	
	* first bitmask for counts of shifts saved in D1
    MOVE.W      (A0),D1     * copy address to D0 
    AND.W       #$0E00,D1   * counts of shifts or register #
    
    * second bitmask for either immediate or from a register in D2
    MOVE.W      (A0),D2     * copy address to D0
    AND.W       #$0020,D2   * if 0: immediate, if 1: from register
    
    	* third bitmask for destination register to be shifted in D0
	MOVE.W      (A0),D0     * copy address to D0     
    AND.W       #$0007,D0   * store destination register to be shifted

	
	MOVEM.L		(A7)+,A1	* restore register from stack
	BRA doneOp
	
*********************************************************************************
* Method Name: findMode
* Description: finds the Mode of the effective address   
*
* Preconditions: 3 bits of Mode in D7    
* Postconditions: returns   
*********************************************************************************
*findMode:
*    *example: 0000 0000 0000 0111 - absolute long
*    *bitmask: 0000 0000 0000 0111
*    *         $#0007
*    
*    CMP.W   #$0, D7
*    BEQ     findRegDR
*    
*    CMP.W   #$1, D7
*    BEQ     findRegAR
*    
*    CMP.W   #$2, D7
*    BEQ     findRegARVal
*    
*    CMP.W   #$3, D7
*    BEQ     findRegARPostInc
*    
*    CMP.W   #$4, D7
*    BEQ     findRegARPreDec
*    
*    CMP.W   #$5, D7
*    BEQ     findRegARDisplacement
*    
*    CMP.W   #$6, D7
*    BEQ     findRegARIndex
*    
*    CMP.W   #$7, D7
*    BEQ     findRegOther
*    
*    RTS
*    
**********************************************************************************
** Method Name:    findReg
** Description:        
**
* Preconditions:        
* Postconditions:    
*********************************************************************************
*findReg:
*
*    RTS
*
*********************************************************************************
* Method Name:    eaModeReg
* Description:        
*
* Preconditions:        
* Postconditions:    
*********************************************************************************
*eaModeReg:
*    JSR     findMode
*    JSR     findReg
*    RTS
*
**********************************************************************************
** Method Name:    eaRegMode
** Description:        
**
** Preconditions:  6 bits containing 3 bits register & 3 bits mode in D7   
** Postconditions:    
**********************************************************************************
*eaRegMode:
*
**    JSR     findReg
**    JSR     findMode
*    
*    * example : 001 000
*    * D7 contains a long: 0000 0000 0000 1000 - Data register 1
*    * bitmask: 0000 0000 0011 1000
*    AND.W #$0038, D7
*    
*    
*    CMP.W #$
*
*    RTS	

*********************************************************************************
* Method Name:	printMemAddr
* Description:		prints the address contained in A0
*
* Preconditions:		A0 - the address to print
* Postconditions:	
*********************************************************************************
printMemAddrToSave	REG		A1/D0-D2
printMemAddr:
	MOVEM.L		printMemAddrToSave,-(A7)	* store registers to stack
	
	LEA			addrBuff,A1		* load the buffer to store addresses
	MOVE.B		#0,D0			* i = 0
	MOVE.L		A0,D1			* copy the address into a data register
memAddrLoop:
	MOVE.L		D1,D2
	AND.L		#$F0000000,D2	* bitmask to get most significant digit
	LSL.L		#4,D1			* shift left one digit for next iteration
	
	ROL.L		#4,D2			* rotate most significant digit to least significant digit
	ADD.B		#$30,D2			* convert from hex to ascii
	MOVE.B		D2,(A1,D0)		* store ascii value in buffer
	
	ADDQ.B		#1,D0			* i++
	CMP.B		#8,D0			* wihle i != 8
	BNE			memAddrLoop		* continue
	
	MOVE.B		#$20,(8,A1)		* add space after address
	MOVE.B		#$00,(9,A1)		* null terminated string
	
	LEA			addrBuff,A1		* point back to start of buffer
	JSR			TrapTask13		* print memory address stored in the buffer
	
	MOVEM.L		(A7)+,printMemAddrToSave	* restore register from stack
	RTS

*********************************************************************************
* Method Name: TrapTask13
* Description: Creates a file if none exists, and appends bytes to that file
*   while also echoing the written bytes to the screen.  You shouldn't need to
*   change this code.
*
* Calling Convention: Callee-Saved 
*
* Preconditions & Method Input:
*   A1 points to the null-terminated buffer to write (newline will be added for you)
*
* Postconditions & Output:
*   ALL files that were previously open will be CLOSED (FileIDs will be invalid)
*   See 'Output.txt' in directory for the results, also piped to the console
*
*
*  A2 holds a pointer to null terminated string to write (input)
*  A3 points to the null-terminated file name
*  D3 holds the number of bytes already in the file to write
*
*  D5 holds number of bytes to write
********************************************************************************
toSave REG D0-D5/A2-A3
TrapTask13:
    *******************************************************************
    * Method initialization, regsiter spilling, parameter saving, etc.
    *******************************************************************
    MOVEM.L toSave, -(SP)   ;  Callee-Saved, so save and restore     
      
    MOVEA.L A1, A2 ; save this buffer to write
    LEA outFilename, A3  ; save this for later, too
      
    move #50,d0   
    trap #15 ; close all files, suggested to begin any IO 
    *******************************************************************
    * End Method Init
    *******************************************************************

    ******************************************************************************************
    * Calculate the number of bytes to write by searching for the null in the target buffer A0
    ******************************************************************************************
    CLR.L D5 *D5 is now the number of bytes to write
nullLoop:
    MOVE.B (A1)+, D0
    CMPI.B #0,D0  * compare to null
    BEQ findNullLoopDone
    ADDI.W #1, D5
    BRA nullLoop
    
findNullLoopDone:
    MOVEA.L A3, A1 * reset A1 so it points to the file to write to (to open, next)
    
    ;check if file exists, and open with task 51 if so, otherwise 52
    ;(precondition here is A1 points to the null-terminated filename )
    MOVE.B #51, D0      ;open file (task 51 is existing, 52 is new)
    trap #15
      
    if.w D0 <NE> #0 then.s         ; if file error (404, not found)
        MOVE.B #52, D0             ; open new file (52 is new)
        trap #15
    endi
    
    ********************************************************************************************************* 
    * Seek to END of FILE by counting the number of bytes, closing, reopening, then seeking.
    *    (first, count number of bytes already in the file to obtain seek position)
    *********************************************************************************************************
    Clr.L D3   ;TODO: reg save, D3 is now our count of bytes read
    MOVE.L #1, D2 ; read one byte at a time
    LEA byteRead, A1
    
countLoop:
    MOVE.B #53, D0 ; try to read one byte (TODO: move out of loop)
    trap #15
    
    CMPI.W #1,D0  ;1 == EOF
    BEQ countDone
    ADDI #1, D3
    BRA countLoop
    
countDone:    
    * close this file
     move #56,d0  
     trap #15 
     
     * reopen the target file
     MOVE.L A3,A1
     MOVE #51, D0
     trap #15
     
    * seek to right position, then continue with writing
    MOVE.L D3, D2 ; move the number of bytes found in the file to D2
    MOVE #55, D0  ; position file task
    trap #15

    ******************************************************************************
    * Actually write the buffer to the file, after caculating the number of bytes 
    *  to write and after seeking to the right location in the file for append
    ******************************************************************************

    MOVE.L D5, D2 ; restore this for the actually writing the buffer 
    ; assumes A0 hasnt changed since handed to this method      
    MOVEA.L A2, A1 ; load the address of the buffer we want to write to disk
    ; assumes file ID is still stored in D1.L  
    MOVE.B #54, D0 ; subtask 54 is write to open file (append, or?), assumes D2 holds # of bytes
    trap #15

* leave new line decision to caller
    ; add a newline to the file output
*    LEA NEWLINE, A1
*    MOVE.B #54, D0 
*    MOVE.B #2,D2  ; kills # of bytes to write from input param
*    trap #15
    
    ; finally, close only this file
    MOVE.B #56, D0 ; close file task
    trap #15
  
    ; report to screen
    MOVEA.L A2, A1 ; load the address of the buffer we want to write to disk & screen
    MOVE.B #14, D0	* changed from #13 to #14 to leave new line to caller
    trap #15
      
    ; restore context
    MOVEM.L (SP)+, toSave
    
    RTS
    
    
*----------------------------------------------------------------------------------
* Method Name: AsciiToHex
* Written by : Berger, Modified by Nash
* Date       : 3/1/2019
* Description: Converts chars '0'-'9' and 'a'-'f' to 0-9,a-F
*              Transforms/unpacks 8 chars (8b each) pointed to by A1 into 
*              its (4b each) equivalent hex value 
*  
*  Preconditions & Input
*       A1 (input) points to a memory buffer holding 8 ascii chars (not null-terminated) 
*       This function calls another function (strip_ascii)
*
*  Postconditions & Output
*       D7 (output) holds the converted value 
*       Caller-Saved : D0 is temp, D6 is a loop var
*----------------------------------------------------------------------------------
AsciiToHexRegList REG D0,D6
AsciiToHex     
    MOVEM.L asciiToHexRegList, -(SP)  *save context
    CLR.L D7 * clear our return value
    MOVE.L #8, D6 ; and set up our loop counter

chrLoop
    MOVE.B (A1)+,D0 * Get the first byte
    jsr strip_ascii * Get rid of the ascii code    
    OR.W D0,D7 * Load the bits into D7
    
    subI.B #1,D6  *decrement our loop variable
    BEQ chrDone   *skip shifting if we are done
    
    ASL.L #4,D7 * shift left 4 bits to prepare for next byte
    BRA chrLoop

chrDone
    MOVEM.L (SP)+,asciiToHexRegList 
    RTS


**********************************************************************
* SUBROUTINE: strip_ascii
* remove the ascii code from the digits 0-9,a-f, or A-F
* Input Parameters: <D0> = ascii code
*
* Return parameters: D0.B = number 0...F, returned as 00...0F
* Registers used internally: D0
* Assumptions: D0 contains $30-$39, $41-$46 or $61-66
*
***********************************************************************
strip_ascii
      CMP.B #$39,D0 * Is it in range of 0-9?
      BLE sub30 * Its a number
      CMP.B #$46,D0 * Is is A...F?
      BLE sub37 * Its A...F
      SUB.B #$57,D0 * Its a...f
      BRA ret_sa * Go back
sub37 SUB.B #$37,D0 * Strip 37
      BRA ret_sa * Go back
sub30 SUB.B #$30,D0 * Strip 30
ret_sa RTS * Go back

    
* Required variables and constants go here for your Disassembler
CR                  EQU $0D
LF                  EQU $0A
NEWLINE             DC.B CR,LF,0  
MSG1                DC.B 'MOVE.L D4,D5',0
MSG2                DC.B 'ADD.B D0,D1',0
inFilename	DC.B	'Config.cfg',0
outFilename         DC.B 'Output.txt',0
byteRead            DS.B 1
ascii_val           DC.B $31,$41,$30,$30,$31,$41,$30,$30 * Test value $1A001A00
stackStart		EQU		$8000
addrBuff		DS.B		10


strGroup5           DC.B    'Group 5 :) ',0
strGroup8           DC.B    'Group 8 :) ',0
strGroup9           DC.B    'Group 9 :) ',0
strGroupB           DC.B    'Group B :) ',0
strGroupC           DC.B    'Group C :) ',0
strGroupD           DC.B    'Group D :) ',0
strGroupE           DC.B    'Group E :) ',0


; Anwar's commands
moveaWMsg   DC.B    'MOVEA.W',0
moveaLMsg   DC.B    'MOVEA.L',0
moveBMsg	    DC.B	    'MOVE.B',0
moveWMsg    	DC.B    	'MOVE.W',0
moveLMsg	    DC.B    	'MOVE.L',0
movemRegMsg	DC.B	    'MOVEM Reg',0
movemMemMsg	DC.B	    'MOVEM Mem',0
subqBMsg    	DC.B	    'SUBQ.B',0
subqWMsg    	DC.B	    'SUBQ.W',0
subqLMsg    	DC.B	    'SUBQ.L',0
subBdnMsg	DC.B	    'SUB.B Dn',0
subWdnMsg	DC.B	    'SUB.W Dn',0
subLdnMsg	DC.B	    'SUB.L Dn',0
subBeaMsg	DC.B	    'SUB.B Ea',0
subWeaMsg	DC.B	    'SUB.W Ea',0
subLeaMsg	DC.B	    'SUB.L Ea',0
addaWMsg    	DC.B	    'ADDA.W',0
addaLMsg    	DC.B	    'ADDA.L',0
addBdnMsg	DC.B	    'ADD.B Dn',0
addWdnMsg	DC.B	    'ADD.W Dn',0
addLdnMsg	DC.B	    'ADD.L Dn',0
addBeaMsg	DC.B	    'ADD.B Ea',0
addWeaMsg	DC.B	    'ADD.W Ea',0
addLeaMsg	DC.B	    'ADD.L Ea',0
cmpMsg		DC.B	    'CMP',0
cmpiMsg		DC.B	    'CMPI',0

; RYAN'S commands
rtsMsg		DC.B	    'RTS',0
jsrMsg		DC.B	    'JSR',0
braMsg		DC.B	    'BRA',0
bcsMsg		DC.B	    'BCS',0
bgeMsg		DC.B	    'BGE',0
bltMsg		DC.B	    'BLT',0
bvcMsg		DC.B	    'BVC',0
bclrMsg		DC.B	    'BCLR',0

; Donghee's commands
mulsMsg		DC.B	    'MULS',0
divsMsg		DC.B	    'DIVS',0
leaMsg		DC.B    'LEA',0
negBMsg		DC.B	    'NEG.B',0
negWMsg		DC.B	    'NEG.W',0
negLMsg		DC.B	    'NEG.L',0
orMsg		DC.B	    'OR',0
oriBMsg     DC.B    'ORI.B',0
oriWMsg     DC.B    'ORI.W',0
oriLMsg     DC.B    'ORI.L',0
eorMsg		DC.B	    'EOR',0
lslBMsg		DC.B    'LSL.B',0
lslWMsg		DC.B    'LSL.W',0
lslLMsg		DC.B    'LSL.L',0
lsrBMsg		DC.B	    'LSR.B',0
lsrWMsg		DC.B	    'LSR.W',0
lsrLMsg		DC.B	    'LSR.L',0
aslMsg		DC.B	    'ASL',0
asrMsg		DC.B	    'ASR',0
rolBMsg		DC.B	    'ROL.B',0
rolWMsg		DC.B	    'ROL.W',0
rolLMsg		DC.B	    'ROL.L',0
rorBMsg		DC.B	    'ROR.B',0
rorWMsg		DC.B	    'ROR.W',0
rorLMsg		DC.B	    'ROR.L',0

dataMsg		DC.B	    'DATA MESSAGE HERE',CR,LF,0

*endOfMsg    DC.B    '',0
*
*addrRegMsg  DC.B    'A',0
*dataRegMsg  DC.B    'D',0
*addrValMsg  DC.B    '(A'
*addrRegIncMsg   DC.B    '(A'
*addrRegDecMsg   DC.B    '-(A'
*addrRegDplMsg   DC.B    ',A'
*addrRegInxMsg   
*prgmCtrDplMsg
*prgmCtrInxMsg


* FOR TESTING PURPOSES
	ORG		$2000
	MULS D7,D6
	JSR		foomethod
	BRA		uselessBranch
uselessBranch
	* MOVE.B  #$11, D7
	* SUBQ    #1,D7
	* ADD     #1,D7
foomethod:
	RTS
	
   END    START        ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
