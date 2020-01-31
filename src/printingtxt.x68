*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here


   lea   filename,a1
   move   #51,d0      open test.txt file
   trap   #15

   lea   buffer,a1
   move   #900,d2      # bytes to read
   move   #53,d0      read from file
   trap   #15
   
   lea buffer,A1
   move.w d2,d1
   move #1,d0
   trap #15
   
   move   #50,d0
   trap   #15  
   
   lea newFileName,a1
   move #52,d0      ; open new file
   trap #15
   
   lea buffer,a1   ; buffer
   move #900,d2      ; # bytes to write
   move #54,d0     ; write buffer to file
   trap #15
    

    SIMHALT             ; halt simulator

* Put variables and constants here

filename   dc.b   'test.txt',0
newFileName dc.b    'output.txt',0
buffer      ds.b   80

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
