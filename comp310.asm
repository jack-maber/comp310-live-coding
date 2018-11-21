    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1

; ---------------------------------------------------------------------------

PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
OAMADDR = $2003
OAMDATA = $2004
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007
OAMDMA = $4014

CONTROLLER1 = $4016 ;controller constants
CONTROLLER2 = $4017

BUTTON_A = 		%10000000
BUTTON_B = 		%01000000
BUTTON_SELECT = %00100000
BUTTON_START =  %00010000
BUTTON_UP = 	%00001000
BUTTON_DOWN = 	%00000100
BUTTON_LEFT = 	%00000010
BUTTON_RIGHT = 	%00000001

ENEMY_HITBOX_WIDTH  = 8
ENEMY_HITBOX_HEIGHT = 8

BULLET_HITBOX_X		 = 3
BULLET_HITBOX_Y		 = 3
BULLET_HITBOX_WIDTH  = 2
BULLET_HITBOX_HEIGHT = 2

max_left = 20
max_right = 60


	.rsset $0010
controller1_state .rs 1
bullet_active     .rs 1
  
	.rsset $0200
sprite_player 	  .rs 4
sprite_bullet 	  .rs 4
sprite_enemy_0    .rs 4

	.rsset $0000
sprite_y		  .rs 1
sprite_tile		  .rs 1
sprite_attrib	  .rs 1
sprite_x		  .rs 1

	.rsset $0000
enemy_alive		  .rs 1

	
	.bank 0
    .org $C000

; Initialisation code based on https://wiki.nesdev.com/w/index.php/Init_code
RESET:
    SEI        ; ignore IRQs
    CLD        ; disable decimal mode
    LDX #$40
    STX $4017  ; disable APU frame IRQ
    LDX #$ff
    TXS        ; Set up stack
    INX        ; now X = 0
    STX PPUCTRL  ; disable NMI
    STX PPUMASK  ; disable rendering
    STX $4010  ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; If the user presses Reset during vblank, the PPU may reset
    ; with the vblank flag still true.  This has about a 1 in 13
    ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
    ; flag now so the vblankwait1 loop sees an actual vblank.
    BIT PPUSTATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblankwait1:  
    BIT PPUSTATUS
    BPL vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    TXA
clrmem:
    STA $000,x
    STA $100,x
    STA $300,x
    STA $400,x
    STA $500,x
    STA $600,x
    STA $700,x  ; Remove this if you're storing reset-persistent data

    ; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ; display list to be copied to OAM.  OAM needs to be initialized to
    ; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).

    INX
    BNE clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.
	
	
	JSR InitialiseGame
	
	LDA #%10000000	;Percent symbol means binary, enables NMI
	STA PPUCTRL
	
	LDA #%00011000 	;Enable sprite drawer and background
	STA PPUMASK
	
	LDA #0
	STA PPUSCROLL	;Set X scroll
	STA PPUSCROLL 	;Set Y scroll 
	
	; End of initialisation code -- enter an infinite loop
forever:
    JMP forever

InitialiseGame:	;Restarts Game/Begins subroutine
vblankwait2:
    BIT PPUSTATUS
    BPL vblankwait2

	; Reset the PPU High/Low, stops the PPU going out of sync on steps
    LDA PPUSTATUS 	
	
	;Write address $3F00 to the PPU, as this is where the background palette is stored, as you can only write 8 bits at a time, have to do it 2 times
	LDA #$3F ; Hexidecimal, remember the dollar sign!
	STA PPUADDR ;PPU Read/Write address
	LDA #$00
	STA PPUADDR
	
	; Writes background sprite colour
	LDA #$31
	STA PPUDATA
	LDA #$09
	STA PPUDATA
	LDA #$19
	STA PPUDATA
	LDA #$29
	STA PPUDATA
	
	; Sprite pallete
	LDA #$3F ; Hexidecimal, remember the dollar sign!
	STA PPUADDR ;PPU Read/Write address
	LDA #$10
	STA PPUADDR
	
	; Writes background colour
	LDA #$30
	STA PPUDATA
	
	; Writes Sprite palette colour
	LDA #$1F
	STA PPUDATA
	LDA #$2D
	STA PPUDATA
	LDA #$3D
	STA PPUDATA
	
	
	; Write Sprite Data for sprite 0
	LDA #120	;y POSITION
	STA sprite_player + sprite_y
	LDA #0		; Tile number
	STA sprite_player + sprite_tile
	LDA #0		; Attributes
	STA sprite_player + sprite_attrib
	LDA #128	;X position
	STA sprite_player + sprite_x
	
	; Load nametable data for backgrounds
	LDA #$20	;Write address of $2000
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	LDX #0	
LoadNameTableLoop:			;Loads background data table
	LDA NametableData, X
	STA PPUDATA
	INX
	BNE LoadNameTableLoop
	
	
	
	LDA #$10
	STA PPUDATA
	LDA #$11
	STA PPUDATA
	LDA #$12
	STA PPUDATA
	LDA #$13
	STA PPUDATA
	
	;Init enemy
	LDA #1
	STA enemy_alive
	LDA #20	;y POSITION
	STA sprite_enemy_0 + sprite_y
	LDA #1		; Tile number
	STA sprite_enemy_0 + sprite_tile
	LDA #0		; Attributes
	STA sprite_enemy_0 + sprite_attrib
	LDA #128	;X position
	STA sprite_enemy_0 + sprite_x
	
	
	RTS ;Ends subroutine
; ---------------------------------------------------------------------------

; NMI is called on every frame
NMI:
	;Init controller 1
	LDA #1
	STA CONTROLLER1
	LDA #0
	STA CONTROLLER1
	
	; Read controller state of all the buttons
	LDX #0
	STX controller1_state
ReadController:
	LDA CONTROLLER1
	LSR A                 ; Input is placed into carry flag
	ROL controller1_state
	INX
	CPX #8
	BNE ReadController
	
	
	;React to Right Button
	LDA controller1_state
	AND #BUTTON_RIGHT
	BEQ ReadRight_Done 
	LDA sprite_player + sprite_x
	CLC
	ADC #1
	STA sprite_player + sprite_x
ReadRight_Done:

	;React to Down Button
	LDA controller1_state
	AND #BUTTON_DOWN
	BEQ ReadDown_Done
	LDA sprite_player + sprite_y
	CLC
	ADC #1
	STA sprite_player + sprite_y
ReadDown_Done:
	
	;React to Left Button
	LDA controller1_state
	AND #BUTTON_LEFT
	BEQ ReadLeft_Done 
	LDA sprite_player + sprite_x
	SEC
	SBC #1
	STA sprite_player + sprite_x
ReadLeft_Done:

	;React to Up Button
	LDA controller1_state
	AND #BUTTON_UP
	BEQ ReadUp_Done
	LDA sprite_player + sprite_y
	SEC
	SBC #1
	STA sprite_player + sprite_y
ReadUp_Done:	
	
	;React to A Button
	LDA controller1_state
	AND #BUTTON_A
	BEQ ReadA_Done
	; Spawn bullet sprite
	LDA bullet_active
	BNE ReadA_Done ; If there is no active bullet on screen, one will be spawned  
	LDA #1
	STA bullet_active
	LDA sprite_player + sprite_y	;y POSITION
	STA sprite_bullet + sprite_y
	LDA #2		; Tile number
	STA sprite_bullet + sprite_tile
	LDA #0		; Attributes
	STA sprite_bullet + sprite_attrib
	LDA sprite_player + sprite_x	;X position
	STA sprite_bullet + sprite_x

ReadA_Done:


	;Update bullet position
	LDA bullet_active
	BEQ UpdateBullet_Done
	LDA sprite_bullet + sprite_y
	SEC
	SBC #2
	STA sprite_bullet + sprite_y
	;Despawn bullet, as carry flag is clear, thus it has left the screen
	BCS UpdateBullet_Done
	LDA #0
	STA bullet_active
UpdateBullet_Done:

	;Update Enemy
	LDA enemy_alive
	BEQ Update_enemy_next
	LDA sprite_enemy_0 + sprite_x
	SEC
	SBC #1
	STA sprite_enemy_0 + sprite_x
	
	
							   ;			\1		  \2		\3			  \4			\5			  \6			\7
CheckCollisionwithEnemy .macro ; parameters object_x, object_y, object_hit_x, object_hit_y, object_hit_w, object_hit_h, no_collision_label
	
	; Check Collision with bullet
	LDA sprite_enemy_0 + sprite_x
	SEC
	SBC \3
	SEC 
	SBC \5 + 1
	CMP \1
	BCS \7
	CLC
	ADC \5 + 1 + ENEMY_HITBOX_WIDTH
	CMP \1
	BCC \7
	
	;Check Y
	LDA sprite_enemy_0 + sprite_y
	SEC
	SBC \4
	SEC
	SBC \6 + 1
	CMP \2
	BCS \7
	CLC
	ADC \6 + 1 + ENEMY_HITBOX_HEIGHT
	CMP \2
	BCC \7
	.endm
	
	CheckCollisionwithEnemy sprite_bullet+sprite_x, sprite_bullet+sprite_y, #BULLET_HITBOX_X, #BULLET_HITBOX_Y, #BULLET_HITBOX_WIDTH, #BULLET_HITBOX_HEIGHT, Update_enemy_nocollision
	
	;Handle Collision
	LDA #0
	STA bullet_active ;Destroy bullet
	STA enemy_alive	  ;Destroy Enemy
	LDA #$FF
	STA sprite_bullet + sprite_y
	STA sprite_enemy_0 + sprite_y	;Move bullet off screen
Update_enemy_nocollision:
Update_enemy_next:

	;Check collision with player character
	CheckCollisionwithEnemy sprite_player+sprite_x, sprite_player+sprite_y, #0, #0, #8, #8, Update_enemy_nocollisionwithplayer 
	;Handle collision
	JSR InitialiseGame
Update_enemy_nocollisionwithplayer:
	
	
	
	
	
	
	
	
	; Copy sprite data to PPU
	LDA #0
	STA OAMADDR
	LDA #$02 	;Tells where the sprites are stored I.E. $0200
	STA OAMDMA
	
	RTI         ; Return from interrupt

; ---------------------------------------------------------------------------
NametableData:
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$10,$10,$10,$10,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03

; ---------------------------------------------------------------------------

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0

; ---------------------------------------------------------------------------

    .bank 2
    .org $0000
    ; TODO: add graphics
	.incbin "comp310.chr"