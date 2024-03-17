STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h	
	WINDOW_HEIGHT DW 0C8h   
	WINDOW_BOUNDS DW 6 ;variable to check collisions early

	TIME_AUX DB 0 ;variable used when checking if the time has changed

	BALL_OG_X DW 0a0h
	BALL_OG_Y DW 64h
	BALL_X DW 0A0h  ;X position (column) of the ball
	BALL_Y DW 64h  ;Y position (line) of the ball
	BALL_SIZE DW 04h ;size of the ball (how many pixels does the ball have in width and height)
	BALL_VELOCITY_X DW 05h
	BALL_VELOCITY_Y DW 02h
	COUNTER_L DB 0
	COUNTER_R DB 0
	
	PADDLE_L_X DW 0Ah
	PADDLE_L_Y DW 0Ah
	PADDLE_R_X DW 130h
	PADDLE_R_Y DW 0Ah
	PD_L_P DB 0
	PD_R_P DB 0
	
	PADDLE_WIDTH DW 05h
	PADDLE_HEIGHT DW 1fh
	PADDLE_VELOCITY DW 05h
	
DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE, DS:DATA, SS:STACK ;assume as code, data and stack segments the respective registers
	PUSH DS 							;push to the stack the DS segments
	SUB AX, AX 						    ;clean the AX register
	PUSH AX 							;push AX to the stack
	MOV AX,DATA 						;save on the AX register the contents of the DATA segment
	MOV DS, AX 							;save on the DS segment the contents of AX
	POP AX								;release the top item from the stack to the AX register
	POP AX								;release the top item from the stack to the AX register

		CALL RESET_SCREEN

		CHECK_TIME:
		
			MOV AH, 2Ch ;get system time
			INT 21h ;CH = hour Cl = minute DH = second DL = 1/100 seconds
		
			CMP DL, TIME_AUX
			JE CHECK_TIME
		    MOV TIME_AUX, DL ;update time

			
			CALL RESET_SCREEN
			CALL MOVE_BALL
			CALL DRAW_BALL
			
			CALL MOVE_PADDLES
			CALL DRAW_PADDLES
			
			JMP CHECK_TIME ;after everything, check time again
		
		RET
	MAIN ENDP

	DRAW_BALL PROC NEAR 
	
		MOV CX,BALL_X  ;set the initial column (X)
		MOV DX,BALL_Y  ; set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL: 
			MOV	AH,0Ch  ;set the configuration to writing a pixel
			MOV AL,0Fh  ;choose white as color
			MOV BH,00h  ;set the page number
			INT 10h     ;executes the configuration
			
			INC CX      ;CX = CX + 1
			MOV AX,CX   ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We go to the next column)
			SUB AX, BALL_X
			CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX, BALL_X ;the CX register goes back to the initial column
			INC DX         ;we advance one line
			
			MOV AX, DX		;DX - BALL_Y > BALL_SIZE (Y-> we exit this procedure, N -> we continue to the next line)
			SUB AX, BALL_Y
			CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL

		
		
		RET
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR

		MOV CX, PADDLE_L_X  
		MOV DX, PADDLE_L_Y
	
		 
		DRAW_PADDLE_L_H:

			MOV	AH,0Ch  ;set the configuration to writing a pixel
			MOV AL,0Fh  ;choose white as color
			MOV BH,00h  ;set the page number
			INT 10h     ;executes the configuration
			
			INC CX      
			MOV AX,CX  
			SUB AX, PADDLE_L_X
			CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_L_H
			
			MOV CX, PADDLE_L_X ;the CX register goes back to the initial column
			INC DX         ;we advance one line
			
			MOV AX, DX		;DX - BALL_Y > BALL_SIZE (Y-> we exit this procedure, N -> we continue to the next line)
			SUB AX, PADDLE_L_Y
			CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_L_H

		MOV CX, PADDLE_R_X  
		MOV DX, PADDLE_R_Y
	
		 
		DRAW_PADDLE_R_H:

			MOV	AH,0Ch  ;set the configuration to writing a pixel
			MOV AL,0Fh  ;choose white as color
			MOV BH,00h  ;set the page number
			INT 10h     ;executes the configuration
			
			INC CX      
			MOV AX,CX  
			SUB AX, PADDLE_R_X
			CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_R_H
			
			MOV CX, PADDLE_R_X ;the CX register goes back to the initial column
			INC DX         ;we advance one line
			
			MOV AX, DX		;DX - BALL_Y > BALL_SIZE (Y-> we exit this procedure, N -> we continue to the next line)
			SUB AX, PADDLE_R_Y
			CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_R_H

		RET
			
			
	DRAW_PADDLES ENDP

	MOVE_BALL PROC NEAR
		
		MOV AX, BALL_VELOCITY_X
		ADD BALL_X, AX
		
		MOV AX, WINDOW_BOUNDS
		CMP BALL_X, AX
		JL PLAYER_TWOP
		
		MOV AX, WINDOW_WIDTH
		SUB AX, BALL_SIZE
		SUB AX, WINDOW_BOUNDS
		CMP BALL_X, AX
		JG PLAYER_ONEP
		JMP MOVE_BALL_VERT
		
		PLAYER_TWOP:
			INC PD_R_P
			CALL RESET_BALL_POSITION
			CMP PD_R_P, 05h
			JGE GAME_OVER
			RET
		PLAYER_ONEP:
			INC PD_L_P
			CALL RESET_BALL_POSITION
			CMP PD_L_P, 05h
			JGE GAME_OVER
			RET
			
		GAME_OVER:
			MOV PD_L_P, 00h
			MOV PD_R_P, 00h
			RET
		MOVE_BALL_VERT:
		MOV AX, BALL_VELOCITY_Y
		ADD BALL_Y, AX
		MOV AX, WINDOW_BOUNDS
		CMP BALL_Y, AX
		JL NEG_VELOCITY_Y
		JMP outcolldebug
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y
			RET	
		outcolldebug:
		MOV AX, WINDOW_HEIGHT
		SUB AX, BALL_SIZE
		SUB AX, WINDOW_BOUNDS
		CMP BALL_Y, AX
		JG NEG_VELOCITY_Y
		
		;collisions WITH AABB
		;right paddle
		MOV AX, BALL_X
		ADD AX, BALL_SIZE
		CMP AX, PADDLE_R_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX, PADDLE_R_X
		ADD AX, PADDLE_WIDTH
		CMP BALL_X, AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX, BALL_Y
		ADD AX, BALL_SIZE
		CMP AX, PADDLE_R_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX, PADDLE_R_Y
		ADD AX, PADDLE_HEIGHT
		CMP BALL_Y, AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
		JMP NEG_VELOCITY_X		
		
		;left paddle
		CHECK_COLLISION_WITH_LEFT_PADDLE:
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_L_X
		JNG EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		
		MOV AX,PADDLE_L_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_L_Y
		JNG EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		
		MOV AX,PADDLE_L_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		
;       If it reaches this point, the ball is colliding with the left paddle	

		JMP NEG_VELOCITY_X
		
		NEG_VELOCITY_X:
			NEG BALL_VELOCITY_X
			RET
		
		
		EXIT_COLLISION_CHECK:
			RET
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR
		
		MOV AH, 01h
		INT 16h
		JZ CHECK_R_PADDLE_MOVEMENT  ;if zero flag is = 1, that means any key is activated, so if ZF = 0, keyISpressed

		MOV AH, 00h
		INT 16h
		
		PADDLE_LEFT:
		
			CMP AL, 77h  ;in ascii is 'w'
			JE MOVE_L_PADDLE_UP
			CMP AL, 57h  ;in ascii is 'W'
			JE MOVE_L_PADDLE_UP
			CMP AL, 73h  ;in ascii is 's'
			JE MOVE_L_PADDLE_DOWN
			CMP AL, 53h  ;in ascii is 'S'
			JE MOVE_L_PADDLE_DOWN
			JMP CHECK_R_PADDLE_MOVEMENT
		
			MOVE_L_PADDLE_UP:
				
				MOV AX, PADDLE_VELOCITY
				SUB PADDLE_L_Y, AX
				MOV AX, WINDOW_BOUNDS
				CMP PADDLE_L_Y, AX
				JL BOUNDS_PADDLE_L_TOP
				JMP CHECK_R_PADDLE_MOVEMENT
				
				BOUNDS_PADDLE_L_TOP:
					MOV PADDLE_L_Y, AX
					JMP CHECK_R_PADDLE_MOVEMENT
				
			MOVE_L_PADDLE_DOWN:
				
				MOV AX, PADDLE_VELOCITY
				ADD PADDLE_L_Y, AX
				MOV AX, WINDOW_HEIGHT
				SUB AX, WINDOW_BOUNDS
				SUB AX, PADDLE_HEIGHT
				CMP PADDLE_L_Y, AX
				JG BOUNDS_PADDLE_L_DOWN
				JMP CHECK_R_PADDLE_MOVEMENT
				
				BOUNDS_PADDLE_L_DOWN:
					
					MOV PADDLE_L_Y, AX
					JMP CHECK_R_PADDLE_MOVEMENT
				
		
		CHECK_R_PADDLE_MOVEMENT:
		
			;if it is 'o' or 'O' move up
			CMP AL,6Fh ;'o'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL,4Fh ;'O'
			JE MOVE_RIGHT_PADDLE_UP
			
			;if it is 'l' or 'L' move down
			CMP AL,6Ch ;'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL,4Ch ;'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			

			MOVE_RIGHT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_R_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_R_Y,AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV PADDLE_R_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_R_Y,AX
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_R_Y,AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_R_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
		
		EXIT_PADDLE_MOVEMENT:
		RET
	
	MOVE_PADDLES ENDP
		
	RESET_BALL_POSITION PROC NEAR
	
		MOV AX, BALL_OG_X
		MOV BALL_X, AX
		
		MOV AX, BALL_OG_Y
		MOV BALL_Y, AX
	
		RET
	
	RESET_BALL_POSITION ENDP
	
	RESET_SCREEN PROC NEAR
		MOV AH, 00h ;set the configuration video mode
		MOV AL, 13h ;choose the video mode
		INT 10h     ;executes the configuration
			
		MOV AH, 0Bh ;set the configuration
		MOV BH, 00h ;to the background color
		MOV BL, 00	;choose black as background color
		INT 10h     ;execute the configuration
		
		RET
	RESET_SCREEN ENDP
	

CODE ENDS
END

