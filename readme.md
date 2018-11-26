# comp310 - Constrained development task
## Max MadNES - A demake of Mad Max (2015) for the Nintendo Entertainment System written in 6502 Assembly
Controls in FCEUX emulator:
* Arrow Keys - Move the interceptor
* F button - Shoot 

I got most of the features that I wanted in such as the scrolling background and the scoring system, however the game loop is a bit dull as I couldn't work out a consistent way of clamping the enemy movement, and thus it remains on a set movement path. That and the fuel pick-up mechanic were the only features that I feel I slightly overscoped on. 


## Compiling Process 
To compile, use shift-right mouse to open a PowerShell window in the repository folder where the ASM file is located, then use ".\tools\nesasm_win32\nesasm.exe .\comp310.asm" (If compilling with NESASM), the .NES file that is then created can then be played in an emulator, although I have included the file for ease of marking. 

## Trello
https://trello.com/b/DS3o658c/comp-310
