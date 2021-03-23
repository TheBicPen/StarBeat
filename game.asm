######################################################################
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Alexander Efimov, efimoval, 1004929759
#
# Bitmap Display Configuration:
# -Unit width in pixels: 8 (update this as needed)
# -Unit height in pixels: 8 (update this as needed)
# -Display width in pixels: 512 (update this as needed)
# -Display height in pixels: 256 (update this as needed)
# -Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# -Milestone 1/2/3/4 (choose the one the applies)
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
#... (add more if necessary)
#
# Link to video demonstration for final submission:
# -(insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well! https://github.com/TheBicPen/CSCB58-Project (email me if I forget to make this public)
#
# Any additional information that the TA needs to know:
# - Make sure your volume isn't too high before starting the game. There is sound.
# - 
######################################################################

######## Constants
.eqv 	SCREEN_WIDTH	32	# units
.eqv 	SCREEN_HEIGHT	64	# units
.eqv 	FRAME_BUFFER	0x10008000
.eqv 	INPUT_BUFFER	0xffff0000

.eqv	AUDIO_DURATION	200	# length of a single note in milliseconds
.eqv	INSTRUMENT	81	# MIDI instrument to play notes with
.eqv	AUDIO_VOLUME	100

# not used. see frame-delay below. TODO: use this for realtime note implementation
#.eqv	SLEEP_AFTER_NOTE	180	# time between notes/frames

# Use frame-based delay for notes - realtime syscalls are expensive
.eqv	FRAME_DELAY	5	# sleep between  - 200fps
.eqv	FRAMES_PER_NOTE	15	# How many frames there are per note - delay should be ~100ms

.eqv	SONG1_LENGTH	64	# number of notes in song1

.eqv	OBJECT_SPEED	5
.eqv	PLAYER_SPEED	7

.eqv	SHIP_COLOUR1	0x0000bb
.eqv	SHIP_COLOUR2	0x888888
#.eqv	SHIP_COLOUR3	0xff9900

.eqv	ENEMY_COLOUR1	0x555555
.eqv	ENEMY_COLOUR2	0x777777
.eqv	ENEMY_COLOUR3	0x444444


.data
# Short song loop - simplified version of https://onlinesequencer.net/634591
# store the pitch only. 0 indicates no note played
song1:	.byte  59, 54, 47, 54, 54, 49, 0, 49, 55, 50, 43, 50, 60, 55, 48, 55, 59, 0, 59, 0, 54, 0, 54, 0, 55, 0, 55, 0, 60, 0, 60, 0, 59, 54, 47, 54, 54, 49, 0, 49, 55, 50, 43, 50, 60, 55, 48, 55, 59, 59, 59, 59, 58, 58, 58, 58, 57, 57, 57, 57, 58, 58, 58, 58

ship_location: 		.byte	0:2	# x,y coordinates of ship
obstacle_locations:	.byte	0:16	# up to 8 objects on screen, all with x,y coordinates



.text

######## Macros

# Load 0s into colour registers and jump to draw call if arg $a2 != 0
# Otherwise, jump to load_colours
# Can be simplified to 1 param version if load_colours is before macro, but this is slower in runtime
.macro check_undraw (%draw_label, %load_colours)
	beqz $a2, %load_colours
	move $t1, $zero
	move $t2, $zero
	move $t3, $zero
	j %draw_label
.end_macro


# Takes x,y coordinates in $a0, $a1, and puts the address of that pixel in $t0
# Note: overwrites $t1
.macro xy_address
	sll $a0, $a0, 2			# 4 bytes
	sll $a1, $a1, 2
	addi $t0, $a0, FRAME_BUFFER	# frame buffer + x offset -> $t0
	mul $t1, $a1, SCREEN_WIDTH	# calculate y-offset
	add $t0, $t1, $t0		# store frame buffer address for object in $t0
.end_macro
	
	
# pop from stack into register reg
.macro pop_stack (%reg)
	lw %reg, 0($sp)
	addi $sp, $sp, 4
.end_macro

# push onto stack
.macro push_stack (%reg)
	addi $sp, $sp, -4 
	sw %reg, 0($sp)
.end_macro


.globl main


## Saved registers for main:
# s0: music note index
# s1: frame count
# s4: reserved for functions (listed below)
# s5: reserved for functions (listed below)
# s6: ship X coordinate
# s7: ship Y coordinate

# Functions that may use s4:
# - handle_input: saves return address
# Functions that may use s5:

main:
	# test
	#j test_instruments
	li $t0, FRAME_BUFFER # $t0 stores the base address for display
	li $t1, 0xff0000	# $t1 stores the red colour code
	li $t2, 0x00ff00	# $t2 stores the green colour code
	li $t3, 0x0000ff	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red. 
	sw $t2, 4($t0)		# paint the second unit on the first row green. Why $t0+4?
	sw $t3, 128($t0)	# paint the first unit on the second row blue. Why +128?
	
	jal clear_screen
	li $s6, 10		# init ship X 
	li $s7, 40		# init ship Y

	# draw ship at initial position
	move $a0, $s6
	move $a1, $s7
	move $a2, $zero
	jal draw_ship
	
	li $s0, 0 		# init note index iterator
	#li $s1, SONG1_LENGTH	# store song length constant
	jal pause		# Pause to let MARS load the simulator
loop:
	# check for key input and handle it if necessary
	li $t9, INPUT_BUFFER 
	lw $t8, 0($t9)
	bne $t8, 1, loop_music
	lw $a0, 4($t9) 			# this assumes $t9 is set to 0xfff0000 from before
	jal handle_input
	


loop_music:		
	# Play notes of song
	#bge $s0, SONG1_LENGTH, end			# terminate once song finishes
	blt $s1, FRAMES_PER_NOTE, loop_end		# don't play note if enough frames haven't passed
	move $s1, $zero					# reset frame counter
	blt $s0, SONG1_LENGTH, loop_music_continue 	# play next note - don't reset to start 
	move $s0, $zero					# reset to start of song
loop_music_continue:
	# play a note from the song
	lb $a0, song1($s0)		# load note
	beqz $a0, loop_empty_note
	jal play_single_note		# play note if pitch is not 0
loop_empty_note:
	addi $s0, $s0, 1		# increment note index
loop_end:
	# do miscellaneous end-of-loop tasks
	jal pause 		# pause until next frame
	addi $s1, $s1, 1	# increment frame counter
	j loop			# keep looping
	
end:	li $v0, 10 		# terminate the program gracefully
	syscall



# pause between notes.
pause:
	li $a0, FRAME_DELAY
	li $v0, 32
	syscall
	jr $ra

# params: $a0: key input, $s6: ship X, $s7: ship Y
# s6 and s7 are treated as globals that may be mutated by this function
handle_input:
	beq $a0, 0x61, ship_move_left		# ASCII code of 'a' is 0x61 or 97 in decimal
	beq $a0, 0x73, ship_move_down		# ASCII code of 's'
	beq $a0, 0x77, ship_move_up		# ASCII code of 'w'
	beq $a0, 0x64, ship_move_right		# ASCII code of 'd'
	
ship_move_left:
	blez $s6, handle_input_return	# if ship at left edge, pass
	push_stack ($ra)	# save return address pointer
	# undraw ship at current position
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	move $a2, $s6		# move True into param 3: undraw
	jal draw_ship
	# draw ship at new position
	addi $s6, $s6, -1	# update global coords
	move $a0, $s6		# move updated x into param 1
	move $a1, $s7		# move y back into param 2
	move $a2, $zero		# move False into param 3: undraw
	jal draw_ship
	pop_stack ($ra)
	jr $ra
	
ship_move_right:
	bge $s6, 29, handle_input_return	# if ship at right edge, pass
	push_stack ($ra)	# save return address pointer
	# undraw ship at current position
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	li $a2, 1		# move True into param 3: undraw
	jal draw_ship
	# draw ship at new position
	addi $s6, $s6, 1	# update global coords
	move $a0, $s6		# move updated x into param 1
	move $a1, $s7		# move y back into param 2
	move $a2, $zero		# move False into param 3: undraw
	jal draw_ship
	pop_stack ($ra)
	jr $ra
	
ship_move_down:
	bge $s7, 62, handle_input_return	# if ship at lower edge, pass
	push_stack ($ra)	# save return address pointer
	# undraw ship at current position
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	li $a2, 1		# move True into param 3: undraw
	jal draw_ship
	# draw ship at new position
	addi $s7, $s7, 1	# update global coords
	move $a0, $s6		# move x coord back to $a0
	move $a1, $s7		# move updated y into param 2
	move $a2, $zero		# move False into param 3: undraw
	jal draw_ship
	pop_stack ($ra)
	jr $ra
	
ship_move_up:
	blez $s7, handle_input_return	# if ship at upper edge, pass
	push_stack ($ra)	# save return address pointer
	# undraw ship at current position
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	li $a2, 1		# move True into param 3: undraw
	jal draw_ship
	# draw ship at new position
	addi $s7, $s7, -1	# update global coords
	move $a0, $s6		# move x coord back to $a0
	move $a1, $s7		# move updated y into param 2
	move $a2, $zero		# move False into param 3: undraw
	jal draw_ship
	pop_stack ($ra)
	jr $ra
	
handle_input_return:
	jr $ra

######## Functions - call these with jal


clear_screen:
	li $t1, SCREEN_WIDTH
	mul $t1, $t1, SCREEN_HEIGHT
	sll $t1, $t1, 2
	li $t0,  FRAME_BUFFER	# load start address into $t0
	addi $t1, $t1, FRAME_BUFFER	# load final address into $t1
clear_screen_loop:
	sw $zero, 0($t0)		# clear pixel
	addi $t0, $t0, 4
	ble $t0, $t1, clear_screen_loop
	jr $ra
	
# draw the ship at the specified coordinates
# if $t2 != 0, draw background pixels instead
# params: $a0: x, $a1: y, $a2: undraw
# x < 30, y < 63 - leave space for ship, never draw it on the edge
draw_ship:
	xy_address
	check_undraw (draw_ship_draw, draw_ship_colours)
draw_ship_colours:
	li $t1, SHIP_COLOUR1
	li $t2, SHIP_COLOUR2
draw_ship_draw:
	sw $t2, 0($t0)		
	sw $t2, 8($t0)
	sw $t2, 128($t0)
	sw $t1, 132($t0)		
	sw $t2, 136($t0)		
	
	# larger ship design, not used
#	li $t3, SHIP_COLOUR3
#	sw $t2, 4($t0)		
#	sw $t2, 12($t0)
#	sw $t2, 128($t0)
#	sw $t2, 132($t0)		
#	sw $t1, 136($t0)		
#	sw $t2, 140($t0)
#	sw $t2, 144($t0)
#	sw $t3, 260($t0)
#	sw $t3, 268($t0)
	jr $ra


# draw the small enemy at the specified coordinates
# params: $a0: x, $a1: y, $a2: undraw
# x < 30, y < 61 - leave space, never draw it on the edge
draw_enemy1:
	xy_address
	check_undraw (draw_enemy1_draw, draw_enemy1_colours)
draw_enemy1_colours:
	li $t1, ENEMY_COLOUR1
	li $t2, ENEMY_COLOUR2
draw_enemy1_draw:
	sw $t1, 4($t0)		
	sw $t1, 128($t0)
	sw $t2, 132($t0)		
	sw $t1, 136($t0)
	sw $t1, 260($t0)
	jr $ra
	

# draw the large enemy at the specified coordinates
# params: $a0: x, $a1: y, @$a2: undraw
# x < 29, y < 60 - leave space, never draw it on the edge
draw_enemy2:
	xy_address
	check_undraw (draw_enemy2_draw, draw_enemy2_colours)
draw_enemy2_colours:
	li $t1, ENEMY_COLOUR1
	li $t2, ENEMY_COLOUR2
	li $t3, ENEMY_COLOUR3
draw_enemy2_draw:
	sw $t3, 4($t0)
	sw $t3, 8($t0)		
	sw $t3, 128($t0)
	sw $t1, 132($t0)		
	sw $t2, 136($t0)
	sw $t3, 140($t0)		
	sw $t3, 256($t0)
	sw $t2, 260($t0)
	sw $t1, 264($t0)
	sw $t3, 268($t0)
	sw $t3, 388($t0)
	sw $t3, 392($t0)
	jr $ra
	
# draw the medium enemy at the specified coordinates
# params: $a0: x, $a1: y
# x < 30, y < 61 - leave space, never draw it on the edge
draw_enemy3:
	xy_address
	check_undraw (draw_enemy3_draw, draw_enemy3_colours)
draw_enemy3_colours:
	li $t1, ENEMY_COLOUR1
	li $t2, ENEMY_COLOUR2
	li $t3, ENEMY_COLOUR3
draw_enemy3_draw:
	sw $t3, 0($t0)	
	sw $t1, 4($t0)		
	sw $t3, 8($t0)
	sw $t1, 128($t0)
	sw $t2, 132($t0)		
	sw $t1, 136($t0)
	sw $t3, 256($t0)
	sw $t1, 260($t0)
	sw $t3, 264($t0)
	jr $ra
	
	
# play single note (async). param $a0: pitch
play_single_note:
	li $a1, AUDIO_DURATION
	li $a2, INSTRUMENT
	li $a3, AUDIO_VOLUME
	li $v0, 31		# play MIDI async
	syscall

	jr $ra			# return
	

# test instruments
test_instruments:
	li $a0, 64
	li $a1, 500
	li $a2, 0
	li $a3, 100
audio_test_loop:
	li $v0, 1
	move $a0, $a2
	syscall
	li $a0, 64
	li $v0, 33
	syscall
	addi $a2, $a2, 1
	blt $a2, 128, audio_test_loop
	jr $ra



























