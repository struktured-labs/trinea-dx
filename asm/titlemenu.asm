; Issue #16 — title menu: LOAD GAME / NEW GAME / OPTIONS (vertical).
; Hooks use JSL/RTL (not JML/RTS) so program bank returns to CE correctly.

!TM_N           = $18
!TM_ATTR_DIM    = $2A00
!TM_ATTR_BRIGHT = $2C00
!TM_VRAM        = $6020

; -------------------- CE hooks --------------------
org $CE3539
    JSL title_spawn
    RTS

org $CE34EE
    PEA.w !TM_N

; Keep draw bank as CE — tables live in CE free space below.

org $CE3382
    JSL title_nav
    BCC +
    SEP #$20
    JMP $34D5        ; drawall (draw + OAM upload), same as original
+   RTS

org $CE336F
    JML title_start  ; branched to (not JSR); exits via JML

; Skip legacy CONTINUE highlight (LDA #$2C00 : JSR $344C)
org $CE32F4
    NOP #6

; Letter tables in CE free zeros (was unused after $893A)
org $CE893A
title_pairs:
    incbin "bin/title_pairs.bin"
title_xy:
    incbin "bin/title_xy.bin"
title_counts:
    db 9, 8, 7
title_rowbase:
    db 0, 9, 17

; -------------------- EB: font + code --------------------
org $EB0000
title_font:
    incbin "bin/titlefont.bin"

; DMA font during forced blank only
title_dma_font:
    ; $2100/$4200/$420C are write-only — never read them. Wait for vblank,
    ; force-blank, upload on DMA channel 7 (avoid HDMA on ch0), restore $0F.
    PHP
    SEP #$20
-   LDA $4212
    BPL -                    ; wait until vblank (bit7 set)
    LDA #$80
    STA $2100                ; force blank
    STA $2115
    REP #$20
    LDA #!TM_VRAM
    STA $2116
    LDA #title_font
    STA $4372
    LDA.w #2048
    STA $4375
    SEP #$20
    LDA.b #bank(title_font)
    STA $4374
    LDA #$01
    STA $4370
    LDA #$18
    STA $4371
    LDA #$80
    STA $420B                ; channel 7
    LDA #$0F
    STA $2100
    PLP
    RTS

title_spawn:
    PHB
    PHP
    JSR title_dma_font
    SEP #$20
    LDA #$7E
    PHA
    PLB
    REP #$20
    LDA #title_pairs
    STA $00
    LDX #$0000
    LDY #$6000
    LDA.w #!TM_N
    PHA
.loop:
    LDA.l title_xy,x
    STA $0000,y
    LDA.l title_xy+2,x
    STA $0002,y
    LDA $00
    STA $0004,y
    LDA #!TM_ATTR_DIM
    STA $0006,y
    LDA $00
    CLC
    ADC #$0004
    STA $00
    TXA
    CLC
    ADC #$0004
    TAX
    TYA
    CLC
    ADC #$0010
    TAY
    LDA $01,s
    DEC
    STA $01,s
    BNE .loop
    PLA
    ; Brighten row 0 (LOAD GAME)
    LDA #!TM_ATTR_BRIGHT
    LDX #$0000
    LDY.w #9
.bright0:
    STA $6006,x
    PHA
    TXA
    CLC
    ADC #$0010
    TAX
    PLA
    DEY
    BNE .bright0
    PLP
    PLB
    RTL

title_hl_paint:
    PHP
    PHB
    SEP #$20
    LDA #$7E
    PHA
    PLB
    REP #$20
    LDX #$0000
    LDA #!TM_ATTR_DIM
.dim:
    STA $6006,x
    PHA
    TXA
    CLC
    ADC #$0010
    TAX
    PLA
    CPX.w #!TM_N<<4
    BCC .dim
    SEP #$20
    LDA $20
    CMP #$03
    BCC +
    LDA #$00
+   TAX
    LDA.l title_rowbase,x
    STA $00
    LDA.l title_counts,x
    STA $01
    REP #$20
    LDA $00
    AND #$00FF
    ASL #4
    TAX
    LDA $01
    AND #$00FF
    TAY
    LDA #!TM_ATTR_BRIGHT
.br:
    STA $6006,x
    PHA
    TXA
    CLC
    ADC #$0010
    TAX
    PLA
    DEY
    BNE .br
    PLB
    PLP
    RTS

title_nav:
    ; Match original: edge bits in $A9 (Left/Right), plus Up/Down.
    ; Force DBR=$7E so $20 and object attrs land in WRAM.
    PHP
    PHB
    SEP #$20
    LDA #$7E
    PHA
    PLB
    REP #$20
    LDA $A9
    BIT #$000A              ; Up/Left → prev
    BNE .prev
    BIT #$0005              ; Down/Right → next
    BNE .next
    PLB
    PLP
    CLC
    RTL
.prev:
    LDA $20
    AND #$00FF
    DEC
    BPL .set
    LDA #$0002
    BRA .set
.next:
    LDA $20
    AND #$00FF
    INC
    CMP #$0003
    BCC .set
    LDA #$0000
.set:
    SEP #$20
    STA $20
    REP #$20
    JSR title_hl_paint
    PLB
    PLP
    SEC
    RTL

title_start:
    REP #$20
    LDA.l $7E0020
    AND #$00FF
    CMP #$0002
    BNE .orig
    JML $CE3326              ; OPTIONS → same path as Select
.orig:
    SEP #$20
    LDA #$01
    JSL $C08419
    JML $CE35ED
