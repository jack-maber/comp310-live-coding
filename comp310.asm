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
   
vblankwait2:
    BIT PPUSTATUS
    BPL vblankwait2

	; Reset the PPU High/Low, stops the PPU going out of sync on steps
    LDA PPUSTATUS 
	
	
	;Write address $3F10 to the PPU, as this is where the background colour is stored, as you can only write 8 bits at a time, have to do it 2 times
	LDA #$3F ; Hexidecimal, remember the dollar sign!
	STA PPUADDR ;PPU Read/Write address
	LDA #$10
	STA PPUADDR
	
	; Writes background colour
	LDA #$30
	STA PPUDATA
	
	; Writes palette colour
	LDA #$1F
	STA PPUDATA
	LDA #$2D
	STA PPUDATA
	LDA #$10
	STA PPUDATA
	
	; Writes palette colour for sprite 1
	LDA #$30
	STA PPUDATA
	LDA #$16
	STA PPUDATA
	LDA #$2D
	STA PPUDATA
	LDA #$10
	STA PPUDATA
	
	
	
	; Write Sprite Data for sprite 0
	LDA #120	;y POSITION
	STA $0200
	LDA #0		; Tile number
	STA $0201
	LDA #0		; Attributes
	STA $0202
	LDA #128	;X position
	STA $0203
	
	; Write Sprite Data for sprite 1
	LDA #60	;y POSITION
	STA $0204
	LDA #1		; Tile number
	STA $0205
	LDA #1		; Attributes
	STA $0206
	LDA #190	;X position
	STA $0207
	
	LDA #%10000000	;Percent symbol means binary, enables NMI
	STA PPUCTRL
	
	LDA #%00010000 	;Enable sprite drawer
	STA PPUMASK
	
	; End of initialisation code -- enter an infinite loop
forever:
    JMP forever

; ---------------------------------------------------------------------------

; NMI is called on every frame
NMI:
    ; Move Sprite 0 left to right
	LDA $0203 
	CLC 
	ADC #1	;Incrementation bit
	STA $0203
	
	; ; Move Sprite 1 top to bottom
	LDA $0204 
	CLC 
	ADC #1	;Incrementation bit
	STA $0204
	
	LDA #0
	STA OAMADDR
	LDA #$02 	;Tells where the sprites are stored I.E. $0200
	STA OAMDMA
	
	RTI         ; Return from interrupt

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