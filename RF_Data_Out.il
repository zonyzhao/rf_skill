;; Load the file containing the basic schematic procedures
load("./skill/ece432Schematic.il")
/*====================================================================
 Define the procedure for creating schematic of a RF column with one bitcell selected in NROW bitcells
 This procedure has 4 parameter:
 - libName: the name of the library that you will put the cell schematic in;
 - cellName: the name of the cell you will create;
 - NROW: the number of rows;
 - bcType: 6T or 8T cell;
=====================================================================*/
procedure(RF(libName cellName Wordsize)

  ;; Define the local variables
  prog((cvid x y pin pinName i cnt BitcellName inst inputsignal)
    
 ;; Open the cell and its schematic view
    cvid = dbOpenCellViewByType(libName cellName "schematic" "schematic" "a")
	
	;; Clean the schematic view
    ece432DeleteObjectsSchematic(cvid)
	
	;; The coordinate of the origin point for the schematic
    x=0
    y=0
	
    ;; Create top level pins
	;; Create input pins
    foreach(pinName list("VDD" "VSS" "CLK_IN" sprintf(nil "DIN<%L:0>" Wordsize-1))
      pin=ece432SchematicCreatePin(cvid pinName "input" x:y "R0")
      y=y+0.5
    )

    foreach(pinName list(sprintf(nil "DOUT<%L:0>" Wordsize-1))
	pin=ece432SchematicCreatePin(cvid pinName "output" x:y "R0")
	y=y+0.5
	)

;; To create input buffer for stimuli
    y=y+1
    cnt=1
    foreach(inputsignal list("CLK")
	
	inst = ece432SchematicCreateInst(
	           	   ;; Cell view id
			   cvid 
			   
			   ;; Name of the library containing the bitcell
			   libName
			   
	           	   ;; The bitcell name  
              		   "inv_chain"  
			   
			   ;; Cell view type, always be "symbol" here
			   "symbol" 
			   
			   ;; Instance name
	           sprintf(nil "Buffer_%d" cnt) 
			   
			   ;; The following list defines the connections of the left side pins 
			   ;; in the symbol view; For our bitcell, 'VDD' 'VSS' 'BL' are pins on the left.
			   ;; The inverter pin 'WL' is connected with the net WL.
			   ;; If there are multiple pins on the left side, you can use the below way to define.
			   ;;    list(list("in1" in1net)
			   ;;         list("in2" in2net))
			   ;; If there is no pin on the left side, this parameter should be 'nil'.
	           list(list("VDD" "VDD")
			list("VSS" "VSS")
			list("IN" sprintf(nil "%s_IN" inputsignal)) )   
			   
			   ;; The following list defines the connections of the right side pins 
			   ;; in the symbol view; For our bitcell, 'BLB' is the only pin on the right.
	  		   list(list("OUT" inputsignal ))  
			   
			   ;; The following list defines the connections of the top side pins 
			   ;; in the symbol view; For our inverter, 'VDD' is the only pin on the top.
      		   nil
			   
			   ;; The following list defines the connections of the bottom side pins 
			   ;; in the symbol view; For our bitcell, this parameter should be 'nil'.
	           nil
			   
			   ;; Location of the instance
                   x:y 
			   
			   ;; Rotation of the instance, such as "R0", "R90", "R180", "R270", "MX", "MY", ...
		   "R0"
			 ) ;; end inst
	y=y+1
	cnt=cnt+1
	) ;;end foreach inputsignal

    ;; Loop for replicating NROW*NCol_Mux bitcells with Wordsize times
    for(i 1 Wordsize
	;; The coordinate of the origin point for the schematic
    x=x+3
    y=0
	
	;; Loop for replicating Bank_Mux_DFF with WordSize times
   
      inst = ece432SchematicCreateInst(
	           	   ;; Cell view id
			   cvid 
			   
			   ;; Name of the library containing the bitcell
			   libName
			   
	           	   ;; The cell name  
              		   "Data_Out"  
			   
			   ;; Cell view type, always be "symbol" here
			   "symbol" 
			   
			   ;; Instance name
	           sprintf(nil "Data_Out_%L" i) 
			   
			   ;; The following list defines the connections of the left side pins 
			   ;; in the symbol view; For our bitcell, 'VDD' 'VSS' 'BL' are pins on the left.
			   ;; The inverter pin 'WL' is connected with the net WL.
			   ;; If there are multiple pins on the left side, you can use the below way to define.
			   ;;    list(list("in1" in1net)
			   ;;         list("in2" in2net))
			   ;; If there is no pin on the left side, this parameter should be 'nil'.
	           list(list("VDD" "VDD")
			list("VSS" "VSS")
			list("DIN" sprintf(nil "DIN<%L>" i-1) )
			list("CLK" "CLK") ) 
			   
			   ;; The following list defines the connections of the right side pins 
			   ;; in the symbol view; For our bitcell, 'BLB' is the only pin on the right.
	  		   list(list("DOUT" sprintf(nil "DOUT<%L>" i-1) ))  
			   
			   ;; The following list defines the connections of the top side pins 
			   ;; in the symbol view; For our inverter, 'VDD' is the only pin on the top.
      		   nil
			   
			   ;; The following list defines the connections of the bottom side pins 
			   ;; in the symbol view; For our bitcell, this parameter should be 'nil'.
	           nil
			   
			   ;; Location of the instance
                   x:y 
			   
			   ;; Rotation of the instance, such as "R0", "R90", "R180", "R270", "MX", "MY", ...
		   "R0"
			 );; end inst 
        
	  ;; The next inverter will be put at the right side of the current one.   
	  
	  
 
        );; end for i in Wordsize
;; To add buffer


	;; Check, save and close the cell view
	schCheck(cvid)  ;; check the schematic connectivity
    dbSave(cvid)
    dbClose(cvid)
	
    return(t)
	
  );; end prog
  
);; end procedure


/*====================================================================
 'let' is the main entrance of the skill program.
 We will build schematic for a 6-bit inverter chain as an example.
====================================================================*/
let((Wordsize libName cellName)  ;; N, libName and cellName are variables

  ;; The number of inverters
  Wordsize = 16
  ;; The name of the library we will put the new cell in
  libName="Register_File"
printf("for debug1")
  
  ;; Define the cell name
  sprintf(cellName "Data_Out_%Lb" Wordsize)
printf("for debug2")
  ;; Call the procedure to create the inverter chain schematic
  RF(libName cellName Wordsize)
  
  printf("=== Cell %L Schematic has been created! ===\n", cellName)

) ;;end let
