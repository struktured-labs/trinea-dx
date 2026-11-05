; Issue #16 step 3 — Configuration menu DX rows.
; Rows: Exit, Play Level, Sound Mode, Turbo, Fast foes, Hero Speed, Rumble, Sound Test.
; Sound Effects + Music Play nested under Sound Test (A toggles SFX↔BGM).
; Opts via getopt/setopt (FE:0200). Code in EB; thin D9 stubs for JSR $9A22/$9A9B/$922F.

!CFG_IDX    = $1685
!CFG_SFX    = $168A
!CFG_BGM    = $168C
!CFG_DIFF   = $10BF
!CFG_STEREO = $0438
!CFG_MODE   = $7ECF32       ; 0=SFX on Sound Test, 1=BGM
!CFG_MAX    = $07

; -------------------- hooks in D9 --------------------
org $D9913C
    CMP.b #!CFG_MAX

org $D99159
    JML cfg_right

org $D991CB
    JML cfg_left

org $D9924D
    JSL cfg_draw
    RTS

; A confirm: replace LDA $1685 / BEQ exit / CMP #3 / CMP #4 chain
org $D99097
    JML cfg_confirm

; Init CFG_MODE on config entry (after vanilla zeros SFX/BGM at $9028ish)
; Hook right after STZ $168A / STZ $168C: at $D99028 = 9C 8A 16 9C 8C 16
org $D99035
    JSL cfg_init
    NOP #2                  ; was STZ $168A / STZ $168C (6 bytes)

; D9 stubs so EB can call bank-D9 subroutines
org $D9B010
cfg_str_turbo:      db "Turbo$"
cfg_str_fastfoes:   db "Fast foes$"
cfg_str_herospeed:  db "Hero Speed$"
cfg_str_rumble:     db "Rumble$"
cfg_str_soundtest:  db "Sound Test$"
cfg_str_off:        db "Off   $"
cfg_str_on:         db "On    $"
cfg_str_fast:       db "Fast  $"
cfg_str_faster:     db "Faster$"
cfg_str_sfx:        db "SFX$"
cfg_str_bgm:        db "BGM$"
cfg_str_blank:      db "   $"

cfg_jsr_print:              ; A=id, X=tile, Y=color
    JSR $9A22
    RTL
cfg_jsr_num:                ; A=value (16-bit in), X=tile, Y=digits
    JSR $9A9B
    RTL
cfg_jsr_refresh:            ; redraw via vanilla $922F (colors+draw+cursor sprite)
    JSR $922F
    RTL

; String ID pointer table: id $30..$34 labels, $40..$45 values
org $D99F6E                 ; id $30..$32 (replace SE/MP/blank labels)
    dw cfg_str_turbo
    dw cfg_str_fastfoes
    dw cfg_str_herospeed
; keep id $33+ music track names intact

org $D99FAE                 ; id $50
    dw cfg_str_rumble
    dw cfg_str_soundtest

org $D99F8E                 ; id $40..$46 value strings (past music ids)
    dw cfg_str_off
    dw cfg_str_on
    dw cfg_str_fast
    dw cfg_str_faster
    dw cfg_str_sfx
    dw cfg_str_bgm
    dw cfg_str_blank

; -------------------- EB code --------------------
org $EB0A00

cfg_init:
    PHP
    SEP #$20
    STZ.w !CFG_SFX
    STZ.w !CFG_SFX+1
    STZ.w !CFG_BGM
    STZ.w !CFG_BGM+1
    LDA #$00
    STA.l !CFG_MODE
    PLP
    RTL

cfg_draw:
    PHP
    PHB
    PHX
    PHY
    SEP #$20
    REP #$10
    LDA #$00
    PHA
    PLB
    REP #$20
    LDA #$0003
    STA $16AB
    STA $16AD
    STA $16AF
    STA $16B1
    STA $16B3
    STA $16B5
    STA $16B7
    STA $16B9
    LDA.l !CFG_IDX
    AND #$00FF
    ASL
    TAX
    LDA #$0001
    STA $16AB,x
    SEP #$20
    ; Header
    LDA #$27
    LDX #$01CE
    LDY #$0003
    JSL cfg_jsr_print
    ; Exit
    LDA #$28
    LDX #$028A
    LDY $16AB
    JSL cfg_jsr_print
    ; Play Level + diff
    LDA #$29
    LDX #$030A
    LDY $16AD
    JSL cfg_jsr_print
    LDA.l !CFG_DIFF
    CLC
    ADC #$2A
    LDX #$032C
    LDY #$0003
    JSL cfg_jsr_print
    ; Sound Mode + stereo
    LDA #$2D
    LDX #$038A
    LDY $16AF
    JSL cfg_jsr_print
    LDA.w !CFG_STEREO
    CLC
    ADC #$2E
    LDX #$03AC
    LDY #$0003
    JSL cfg_jsr_print
    ; Turbo + value
    LDA #$30
    LDX #$040A
    LDY $16B1
    JSL cfg_jsr_print
    JSL cfg_val_turbo
    LDX #$042C
    LDY #$0003
    JSL cfg_jsr_print
    ; Fast foes
    LDA #$31
    LDX #$048A
    LDY $16B3
    JSL cfg_jsr_print
    JSL cfg_val_foes
    LDX #$04AC
    LDY #$0003
    JSL cfg_jsr_print
    ; Hero Speed
    LDA #$32
    LDX #$050A
    LDY $16B5
    JSL cfg_jsr_print
    JSL cfg_val_hero
    LDX #$052C
    LDY #$0003
    JSL cfg_jsr_print
    ; Rumble
    LDA #$50
    LDX #$058A
    LDY $16B7
    JSL cfg_jsr_print
    JSL cfg_val_rumble
    LDX #$05AC
    LDY #$0003
    JSL cfg_jsr_print
    ; Sound Test label + SFX/BGM prefix + number (via D9 stub → $9A9B)
    LDA #$51
    LDX #$060A
    LDY $16B9
    JSL cfg_jsr_print
    JSL cfg_val_soundtest
    LDX #$062C
    LDY #$0003
    JSL cfg_jsr_print
    ; number field after prefix (gap so "SFX"/"BGM" stay intact)
    ; blank $0634..$0638: $9A9B writes right-to-left and skips leading zeros,
    ; so tens/hundreds tiles go stale unless cleared first
    SEP #$20
    LDA #$46                ; blank 3 tiles
    LDX #$0634
    LDY #$0003
    JSL cfg_jsr_print
    REP #$20
    LDA.l !CFG_MODE
    AND #$00FF
    BNE +
    LDA.w !CFG_SFX
    BRA ++
+   LDA.w !CFG_BGM
++  AND #$00FF
    LDY #$0003
    LDX #$0638
    JSL cfg_jsr_num
    SEP #$20
    PLY
    PLX
    PLB
    PLP
    RTL

cfg_val_turbo:
    JSL getopt
    AND #$01
    CLC
    ADC #$40
    RTL

cfg_val_foes:
    JSL getopt
    AND #$08
    BEQ +
    LDA #$41
    RTL
+   LDA #$40
    RTL

cfg_val_hero:
    JSL getopt
    LSR
    AND #$03
    BEQ .off
    CMP #$01
    BEQ .fast
    LDA #$43              ; Faster
    RTL
.off:
    LDA #$40
    RTL
.fast:
    LDA #$42
    RTL

cfg_val_rumble:
    JSL getopt
    AND #$20
    BEQ .on
    LDA #$40
    RTL
.on:
    LDA #$41
    RTL

cfg_val_soundtest:
    LDA.l !CFG_MODE
    BNE +
    LDA #$44
    RTL
+   LDA #$45
    RTL

; ---- Right ----
cfg_right:
    PHP
    SEP #$20
    LDA.l !CFG_IDX
    BEQ .none
    CMP #$01
    BEQ .play
    CMP #$02
    BEQ .sound
    CMP #$03
    BEQ .turbo
    CMP #$04
    BEQ .foes
    CMP #$05
    BEQ .hero
    CMP #$06
    BEQ .rumble
    CMP #$07
    BEQ .stest
.none:
    PLP
    JML $D990A6
.play:
    LDA.l !CFG_DIFF
    CMP #$02
    BEQ +
    INC
    STA.l !CFG_DIFF
+   JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.sound:
    PLP
    JML $D9917C           ; vanilla stereo toggle right
.turbo:
    JSL getopt
    EOR #$01
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.foes:
    JSL getopt
    EOR #$08
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.hero:
    JSL getopt
    PHA
    LSR
    AND #$03
    INC
    CMP #$03
    BCC +
    LDA #$00
+   ASL
    STA $00
    PLA
    AND #$F9              ; clear bits 1-2
    ORA $00
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.rumble:
    JSL getopt
    EOR #$20
    AND #$EF              ; keep bit4 clear (retired)
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.stest:
    LDA.l !CFG_MODE
    BNE .st_bgm
    REP #$20
    LDA.l !CFG_SFX
    CMP.w #100
    BCS +
    INC
    STA.l !CFG_SFX
+   SEP #$20
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.st_bgm:
    REP #$20
    LDA.l !CFG_BGM
    CMP.w #29
    BCS +
    INC
    STA.l !CFG_BGM
+   SEP #$20
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6

; ---- Left ----
cfg_left:
    PHP
    SEP #$20
    LDA.l !CFG_IDX
    BEQ .none
    CMP #$01
    BEQ .play
    CMP #$02
    BEQ .sound
    CMP #$03
    BEQ .turbo
    CMP #$04
    BEQ .foes
    CMP #$05
    BEQ .hero
    CMP #$06
    BEQ .rumble
    CMP #$07
    BEQ .stest
.none:
    PLP
    JML $D990A6
.play:
    LDA.l !CFG_DIFF
    BEQ +
    DEC
    STA.l !CFG_DIFF
+   JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.sound:
    PLP
    JML $D991EC           ; vanilla stereo left
.turbo:
    JSL getopt
    EOR #$01
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.foes:
    JSL getopt
    EOR #$08
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.hero:
    JSL getopt
    PHA
    LSR
    AND #$03
    DEC
    BPL +
    LDA #$02
+   ASL
    STA $00
    PLA
    AND #$F9
    ORA $00
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.rumble:
    JSL getopt
    EOR #$20
    AND #$EF
    JSL setopt
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.stest:
    LDA.l !CFG_MODE
    BNE .st_bgm
    REP #$20
    LDA.l !CFG_SFX
    BEQ +
    DEC
    STA.l !CFG_SFX
+   SEP #$20
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6
.st_bgm:
    REP #$20
    LDA.l !CFG_BGM
    BEQ +
    DEC
    STA.l !CFG_BGM
+   SEP #$20
    JSL cfg_jsr_refresh
    PLP
    JML $D990A6

; ---- A confirm ----
; Entry: replaced LDA $1685 at $9096. Must preserve BIT #$8000 already done.
; Stack/P state: SEP #$20 was about to run; we JML here mid-handler.
cfg_confirm:
    SEP #$20
    LDA.l !CFG_IDX
    BEQ .exit
    CMP #$07
    BEQ .stest_a
    ; other rows (incl. former 3/4): soft-beep path
    JML $D990A6
.exit:
    JML $D990B2
.stest_a:
    LDA.l !CFG_MODE
    EOR #$01
    STA.l !CFG_MODE
    JSL cfg_jsr_refresh
    LDA.l !CFG_MODE
    BNE .do_bgm
    JML $D990DA            ; play SFX
.do_bgm:
    JML $D990CB            ; play BGM
