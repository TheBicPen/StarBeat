######################################################################
# CSCB58 Winter2021Assembly Final Project
# University of Toronto, Scarborough## Student: Name, Student Number, UTorID
#
# Bitmap Display Configuration:
# -Unit width in pixels: 8 (update this as needed)
# -Unit height in pixels: 8 (update this as needed)
# -Display width in pixels: 256 (update this as needed)
# -Display height in pixels: 512 (update this as needed)
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
# -yes / no/ yes, and please share this project githublink as well!
#
# Any additional information that the TA needs to know:
# -(write here, if any)
######################################################################

# Constants
.eqv 	SCREEN_WIDTH	64	# units
.eqv 	SCREEN_HEIGHT	32	# units
.eqv 	DISPLAY_ADDRESS	0x10008000
#.eqv	AUDIO_DURATION	200	# length of a single note in milliseconds
.eqv	INSTRUMENT	0	# MIDI instrument to play notes with
.eqv	AUDIO_VOLUME	100	




# test audio
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
	
# play single note (async). param $a0: pitch, param $a1: duration
play_single_note:
	#li $a1, AUDIO_DURATION
	li $a2, INSTRUMENT
	li $a3, AUDIO_VOLUME
	jr $ra			# return





























