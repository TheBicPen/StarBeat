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
# 1. Music loop	(approved by Moshe)
# 2. Smooth graphics - the whole framebuffer is not redrawn each frame - only parts that have changed are redrawn
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
# - Restart MARS before running the code. I'm using the version with the crash fixed, and it gets 1/3 the expected framerate on subsequent executions after running the program once. 
#	It's not very fun to play a laggy game. The first time should run buttery smooth
######################################################################

######## Constants
.eqv 	SCREEN_WIDTH	32	# units
.eqv 	SCREEN_HEIGHT	64	# units
.eqv 	FRAME_BUFFER	0x10008000
.eqv 	INPUT_BUFFER	0xffff0000

# sounds
.eqv	AUDIO_DURATION	200	# Length of a single note in milliseconds. Adjust this based on FRAMES_PER_NOTE and vice-versa.
				# This uses a realtime clock so lag might cause the music to sound wrong, and no lag might cause overlaps if set too high
				# The implementation of this in MARS only allows 1 sound at a time (overlaps cause weird audio glitches)
.eqv	INSTRUMENT	81	# MIDI instrument to play notes with
.eqv	AUDIO_VOLUME	100
# Use frame-based delay for notes - realtime syscalls are expensive
.eqv	FRAME_DELAY	20	# millisecond delay between frames, ie. inverse of framerate. Currently 50 FPS
.eqv	FRAMES_PER_NOTE	5	# How many frames there are per note - delay should be ~100ms

# ong-specific info
.eqv	SONG1_LENGTH	64	# number of notes in song1

# gameplay settings
.eqv	OBJECT_SPEED	3
.eqv 	MAX_HEALTH	3

# colours
.eqv	SHIP_COLOUR1	0x0000bb
.eqv	SHIP_COLOUR2	0x888888
#.eqv	SHIP_COLOUR3	0xff9900
.eqv	ENEMY_COLOUR1	0x555555
.eqv	ENEMY_COLOUR2	0x777777
.eqv	ENEMY_COLOUR3	0x444444
.eqv	HP_COLOUR	0xff0000
.eqv	SHIP_EXPLODE1	0xfc520f
.eqv	SHIP_EXPLODE2	0xfc7e0f
.eqv	SHIP_EXPLODE3	0xfca50f

.data
# Short song loop - simplified version of https://onlinesequencer.net/634591
# store the pitch only. 0 indicates no note played
song1:			.byte  	59, 54, 47, 54, 54, 49, 0, 49, 55, 50, 43, 50, 60, 55, 48, 55, 59, 0, 59, 0, 54, 0, 54, 0, 55, 0, 55, 0, 60, 0, 60, 0, 59, 54, 47, 54, 54, 49, 0, 49, 55, 50, 43, 50, 60, 55, 48, 55, 59, 59, 59, 59, 58, 58, 58, 58, 57, 57, 57, 57, 58, 58, 58, 58
# generated with [3*(x % 8)+4 if x > 0 else 0 for x in above list]
song1_objects:		.byte	13, 22, 25, 22, 22, 7,  0,  7, 25, 10, 13, 10, 16, 25, 4, 25, 13,  0, 13, 0, 22, 0, 22, 0, 25, 0, 25, 0, 16, 0, 16, 0, 13, 22, 25, 22, 22,  7, 0,  7, 25, 10, 13, 10, 16, 25,  4, 25, 19, 15,  9,  5,  2,  6,  10,  14,  7,  7,  7,  7, 12, 10,  8,  6
# make sure that all objects on non-empty notes have a value of 1, 2, or 3
song1_object_type:	.byte	1,  2,  1,  2,  2,  3,  0,  3,  1,  2,  1,  2,  3,  1, 3,  1,  1,  0,  1, 0,  2, 0,  2, 0,  1, 0,  1, 0,  3, 0,  3, 0,  1,  2,  1,  2,  2,  3, 0,  3,  1,  2,  1,  2,  3,  1,  3,  1,  1,  1,  1,  1,  2,  2,  2,  2,  3,  3,  3,  3,  2,  2,  2,  2
object_locations:	.byte	0:32	# up to 8 objects on screen, each with padding to allow indexing by shifting, x,y coordinates, and obj type

game_over_screen_data:	.byte	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 224, 232, 207, 207, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 224, 240, 122, 137, 137, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 188, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 188, 188, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 122, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 188, 188, 0, 0, 0, 188, 232, 224, 188, 0, 0, 0, 0, 0, 0, 0, 0, 232, 237, 0, 224, 188, 0, 0, 0, 0, 122, 244, 188, 0, 0, 0, 188, 188, 0, 0, 188, 224, 122, 224, 188, 122, 232, 208, 115, 232, 122, 232, 122, 255, 122, 237, 244, 188, 188, 0, 0, 188, 232, 122, 232, 122, 0, 0, 0, 255, 0, 0, 188, 188, 0, 0, 0, 232, 122, 115, 128, 251, 122, 188, 224, 188, 0, 255, 224, 188, 188, 0, 255, 218, 88, 122, 237, 122, 0, 0, 0, 255, 0, 0, 231, 224, 0, 0, 255, 0, 0, 0, 188, 250, 122, 122, 244, 188, 0, 244, 203, 188, 188, 188, 188, 170, 255, 232, 232, 0, 0, 0, 0, 188, 240, 203, 244, 0, 0, 224, 224, 0, 0, 0, 224, 224, 0, 0, 255, 122, 0, 244, 203, 188, 188, 122, 232, 0, 0, 0, 122, 0, 0, 0, 0, 0, 224, 232, 0, 0, 0, 244, 203, 188, 232, 255, 231, 250, 0, 0, 232, 122, 0, 251, 160,
				188, 188, 0, 232, 122, 0, 0, 244, 188, 0, 0, 0, 0, 0, 0, 0, 0, 0, 188, 188, 188, 122, 0, 0, 188, 0, 0, 0, 0, 0, 232, 122, 188, 188, 0, 188, 188, 188, 188, 255, 188, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 188, 188, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 188, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 226, 241, 122, 244, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 88, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 232, 122, 0, 122, 232, 0, 0, 0, 0, 0, 0, 232, 0, 0, 122, 188, 188, 0, 0, 170, 88, 0, 122, 188, 0, 0, 0, 0, 0, 0, 0, 188, 188, 0, 0, 224, 224, 0, 255, 0, 0, 0, 188, 122, 0, 188, 232, 188, 188, 0, 0, 170, 88, 224, 232, 188, 255, 232, 0, 0, 0, 0, 0, 232, 122, 0, 0, 244, 122, 0, 232, 122, 0, 224, 240, 0, 122, 244, 0, 0, 0, 188, 0, 232, 203,
				240, 0, 0, 0, 203, 188, 0, 0, 0, 122, 232, 0, 0, 188, 188, 0, 0, 188, 188, 0, 255, 0, 0, 232, 160, 232, 232, 244, 224, 0, 224, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 188, 232, 188, 0, 0, 0, 188, 188, 188, 188, 0, 0, 232, 122, 0, 122, 122, 188, 0, 224, 224, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 244, 160, 0, 0, 0, 0, 0, 255, 255, 0, 0, 0, 224, 240, 122, 122, 224, 224, 0, 224, 224, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 232, 122, 0, 0, 0, 0, 188, 232, 232, 188, 0, 0, 188, 188, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

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
# s1: frames since last note

# s5: ship health
# s6: ship X coordinate
# s7: ship Y coordinate

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
	li $s5, MAX_HEALTH	# Init max health
	li $s6, 14		# init ship X 
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
	# draw ship at possibly updated coordinates
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	move $a2, $zero		# move False into param 3: undraw
	jal draw_ship


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
	
	# drop an object at each note
	lb $a0, song1_objects($s0)		# load X coordinate
	lb $a1, song1_object_type($s0)		# load obj type
	move $a2, $s0				# load note index
	jal drop_object
loop_empty_note:
	addi $s0, $s0, 1		# increment note index
loop_end:
	# do miscellaneous end-of-loop tasks
	
	jal move_objects	# Move objects downwards, remove finished ones, check collisions
	# this could be considered bad design but I just don't want to loop over the game objects 3 times in 3 different functions
	
	jal draw_hp		# draw HP on screen
	blez $s5, game_over	# check for game over
	jal pause 		# pause until next frame
	addi $s1, $s1, 1	# increment frame counter
	j loop			# keep looping
	
end:	li $v0, 10 		# terminate the program gracefully
	syscall


game_over:
	move $a0, $s6
	move $a1, $s7
	jal ship_explode
	jal game_over_screen
	jal pause
	# check for P and handle it if necessary
	li $t9, INPUT_BUFFER 
	lw $t8, 0($t9)
	bne $t8, 1, game_over
	lw $t8, 4($t9)
	beq $t8, 0x70, main	# ASCII code of 'p'
	j game_over		# keep looping until p is pressed

######## Functions - call these with jal

# Draw HP at the top of the screen
# Called from main so ship HP is in $s5
draw_hp:
	sll $t0, $s5, 3		# shift current HP iterator twice for word, once for 1-pixel gap
	addi $t0, $t0, 124	# draw on 2nd line: 124=(32-1)*4
	li $t2, MAX_HEALTH	# init max HP iterator for undraw loop
	sll $t2, $t2, 3		# shift max HP twice for word, once for 1-pixel gap
	addi $t2, $t2, 124	# draw on 2nd line
	li $t3, 0x000000
	li $t1, HP_COLOUR
draw_hp_undraw_loop:		# this might actually be faster than a single loop - O(1) vs. O(n) jumps
	sw $t3, FRAME_BUFFER($t2)	# undraw pixels
	addi $t2, $t2, -8	# move 2 pixels left
	bgt $t2, $t0, draw_hp_undraw_loop
draw_hp_loop:
	sw $t1, FRAME_BUFFER($t0)	# draw 
	addi $t0, $t0, -8	# move 2 pixels left
	bgt $t0, 124, draw_hp_loop
	jr $ra

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
	beq $a0, 0x70, main			# ASCII code of 'p'
	jr $ra					# Else, ignore input
ship_move_left:
	blez $s6, handle_input_return	# if ship at left edge, pass
	push_stack ($ra)	# save return address pointer
	# undraw ship at current position
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	move $a2, $s6		# move True into param 3: undraw
	jal draw_ship
	addi $s6, $s6, -1	# update global coords
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
	addi $s6, $s6, 1	# update global coords
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
	addi $s7, $s7, 1	# update global coords
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
	addi $s7, $s7, -1	# update global coords
	pop_stack ($ra)
	jr $ra
handle_input_return:
	jr $ra
	
# Clear the screen. No params.
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
	
# Game over screen. No params.
game_over_screen:
	li $t1, SCREEN_WIDTH
	mul $t1, $t1, SCREEN_HEIGHT
	sll $t1, $t1, 2
	move $t4, $zero
	li $t0,  FRAME_BUFFER	# load start address into $t0
	addi $t1, $t1, FRAME_BUFFER	# load final address into $t1
game_over_screen_loop:
	#lbu $t2, game_over_screen_data($t4)	# end result looks blue
	lb $t2, game_over_screen_data($t4)	# end result looks pinkish-white
	sll $t3, $t2, 8
	add $t3, $t3, $t2
	sll $t3, $t2, 8
	add $t3, $t3, $t2	# load value into all 
	sw $t3, 0($t0)		# clear pixel
	addi $t0, $t0, 4
	addi $t4, $t4, 1
	ble $t0, $t1, game_over_screen_loop
	jr $ra
	
# animation of ship exploding. Params: ship coords in a0,a1
ship_explode:
	xy_address
	li $t1, SHIP_EXPLODE1
	li $t2, SHIP_EXPLODE2
	li $t3, SHIP_EXPLODE3
	sw $t1, 0($t0)		
	sw $t1, 4($t0)		
	sw $t1, 8($t0)
	sw $t1, 128($t0)
	sw $t1, 132($t0)		
	sw $t1, 136($t0)
	sw $t1, 256($t0)
	sw $t1, 260($t0)		
	sw $t1, 264($t0)
	push_stack($ra)
	jal pause
	sw $t1, -132($t0)
	sw $t1, -128($t0)
	sw $t1, -124($t0)
	sw $t1, -4($t0)
	sw $t2, 0($t0)		
	sw $t2, 4($t0)		
	sw $t2, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 124($t0)
	sw $t2, 128($t0)
	sw $t3, 132($t0)		
	sw $t2, 136($t0)
	sw $t1, 140($t0)
	sw $t1, 152($t0)
	sw $t3, 256($t0)
	sw $t2, 260($t0)		
	sw $t2, 264($t0)
	sw $t1, 268($t0)
	jal pause
	pop_stack($ra)
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
# params: $a0: x, $a1: y, $a2: undraw
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
	
# Assume this gets called by main loop, ie. ship x,y in $s6,$s7
# Modify ship current health, ie. $s5
# params: $s5-$s7, $a0,$a1,$a2: obj x,y,type
check_collision:
# Calculate the Manhattan distance (one-norm) between x1,y1 and x2,y2 ($a0,$a1, $s6,$s7) and store in $v0
distance:
	sub $v0, $a0, $s6
	abs $v0, $v0
	sub $v1, $a1, $s7
	abs $v1, $v1
	add $v0, $v0, $v1
	beq $a2, 1, check_collision_enemy1
	beq $a2, 2, check_collision_enemy2
	beq $a2, 3, check_collision_enemy3
	j end	# error
check_collision_enemy1:
	blt $v0, 3, decrement_hp
	jr $ra
check_collision_enemy2:
	blt $v0, 4, decrement_hp
	jr $ra
check_collision_enemy3:
	blt $v0, 5, decrement_hp
	jr $ra
decrement_hp:
	addi $s5, $s5, -1
	jr $ra
	
# move objects downwards and remove them once off-screen
# On collision, decrement HP
move_objects:
	push_stack($ra)
	push_stack($s0)
	push_stack($s1)
	push_stack($s2)
	push_stack($s3)
	li $s3, 31	# init iterator to last byte of last array item
move_objects_loop:
	lb $s2, object_locations($s3)	# load obj type
	addi $s3, $s3, -1	# decrement to Y coord
	lb $s1, object_locations($s3)	# load y coord
	move $a1, $s1			# move Y coord to parameter
	addi $s3, $s3, -1	# decrement to X coord
	lb $s0, object_locations($s3)	# load x coord
	move $a0, $s0			# move X coord to parameter

	beq $s2, 0, move_objects_loop_continue	# if obj type == 0, do nothing
	# check collisions
	move $a0, $s0	# load obj X
	move $a1, $s1	# load obj Y
	move $a2, $s2	# load obj type
	jal check_collision		# ship HP,X,Y in $s5-$s7

	li $a2, 1			# undraw first
	beq $s2, 1, move_object_enemy_1
	beq $s2, 2, move_object_enemy_2
	beq $s2, 3, move_object_enemy_3
	j end
move_object_enemy_1:
	jal draw_enemy1
	bgt $s1, 64, move_objects_loop_despawn	# check for off-screen
	li $a2 0	# now draw
	move $a0, $s0	# reload x coord
	add $a1, $s1, OBJECT_SPEED	# move objects down towards ship - load new Y
	addi $s3, $s3, 1		# move to index of Y coord
	sb $a1, object_locations($s3)	# Save new Y coord of moved object
	addi $s3, $s3, -1		# move back to X coord
	jal draw_enemy1		# draw enemy in new location
	j move_objects_loop_continue
move_object_enemy_2:
	jal draw_enemy2
	bgt $s1, 64, move_objects_loop_despawn	# check for off-screen
	li $a2 0	# now draw
	move $a0, $s0	# reload x coord
	add $a1, $s1, OBJECT_SPEED	# move objects down towards ship - load new Y
	addi $s3, $s3, 1		# move to index of Y coord
	sb $a1, object_locations($s3)	# Save new Y coord of moved object
	addi $s3, $s3, -1		# move back to X coord
	jal draw_enemy2		# draw enemy in new location
	j move_objects_loop_continue
move_object_enemy_3:
	jal draw_enemy3
	bgt $s1, 64, move_objects_loop_despawn	# check for off-screen
	li $a2 0	# now draw
	move $a0, $s0	# reload x coord
	add $a1, $s1, OBJECT_SPEED	# move objects down towards ship - load new Y
	addi $s3, $s3, 1		# move to index of Y coord
	sb $a1, object_locations($s3)	# Save new Y coord of moved object
	addi $s3, $s3, -1		# move back to X coord
	jal draw_enemy3		# draw enemy in new location
	j move_objects_loop_continue
move_objects_loop_despawn:
	sb $zero, object_locations($s3)	# unset X coord
	addi $s3, $s3, 1		# move to Y coord 
	sb $zero, object_locations($s3)	# unset Y coord
	addi $s3, $s3, 1		# move to obj type
	sb $zero, object_locations($s3)	# unset obj type
	addi $s3, $s3, -2		# move back to X coord 
	j move_objects_loop_continue
move_objects_loop_continue:
	addi $s3, $s3, -2	# decrement to next item
	bgez $s3, move_objects_loop
	pop_stack($s3)
	pop_stack($s2)
	pop_stack($s1)
	pop_stack($s0)
	pop_stack($ra)
	jr $ra
	
	
# drop object. param $a0: x coord, $a1: object type, $a2: note index
# hope that draw calls don't modify t4
drop_object:
	# calculate object array index to use (note index % 8)
	andi $t1, $a2, 7	# index mod 8
	sll $t1, $t1, 2		# mult. by 4 since each struct stores 4 bytes
	
	move $t0, $a1	# move obj type to temp register since we need a1 for the y coord
	### HERE
	li $a1, -4	# load y coord for draw - spawn object off screen
	addi $t1, $t1, 1		# move to x coord location (skip padding)
	sb $a0, object_locations($t1)	# store x coord
	addi $t1, $t1, 1		# move to y coord location
	sb $a1, object_locations($t1)	# store y coord
	addi $t1, $t1, 1		# move to obj type location
	sb $t0, object_locations($t1)	# store obj type
	li $a2, 0			# draw, not undraw
	push_stack($ra)
	beq $t0, 1, drop_object_enemy_1
	beq $t0, 2, drop_object_enemy_2
	beq $t0, 3, drop_object_enemy_3
	j end
drop_object_enemy_1:
	jal draw_enemy1
	pop_stack($ra)
	jr $ra
drop_object_enemy_2:
	jal draw_enemy2
	pop_stack($ra)
	jr $ra
drop_object_enemy_3:
	jal draw_enemy3
	pop_stack($ra)
	jr $ra

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



























