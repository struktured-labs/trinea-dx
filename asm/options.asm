hirom
; ===== Trinea DX options (beta): runtime toggles stored in unused SRAM tail =====
; SRAM $30:6300 'T', $6301 'D', $6302 opts, $6303 opts^$A5   (invalid -> all OFF = original)
;   opts bit0 turbo (20 Hz logic), bits1-2 hero speed (0 orig, 1 = 5px-equiv, 2 = 6px-equiv), bit3 faster monsters,
;   bit4 RETIRED (was rumble off in afb92e1a/2339e2b8; ignored so saves that toggled it get rumble back),
;   bit5 rumble off (read by asm/rumble.asm rum_muted), bit6 RETIRED (was Start-skips-dialogue off via L+R+Select;
;   ignored and never written by a toggle, so saves that set it still skip),
;   bit7 RETIRED (was Select help overlay off via L+R+Start; ignored so saves that set it still get the overlay)
; scratch (prev buttons, feedback ticks, saved mosaic, raw pad) lives in WRAM !W+4..+11, not SRAM: SRAM is only read when
; the WRAM cache is invalid and only written when a toggle changes (issue #4 real-hardware hardening)
!S = $306300
!W = $7ECF10      ; WRAM cache/scratch (hw fix #4): +0 $A5 = cache valid, +1 opts, +2 sig valid, +3 opts^$5A (cache check), +4..+11 pad/feedback scratch, +12..+15 L/R shortcut phase (issue #16)

; --- main-loop tick wait (both copies): LDA $082C : CMP #$04 -> JSL turbo : NOP
org $C00268
    JSL turbo
    NOP
org $C002A5
    JSL turbo
    NOP

; --- monster step hook (shared enemy 8-dir step routine C1:3A92)
org $C13A92
    JSL mon
    NOP

; --- player collision chain + per-tick hook
; --- joypad read (replaces perf_joy target): keep raw pad in WRAM scratch (!W+10/11). issue #16: no L+R face-button hide
org $C004F8
    JML joy

org $C0FF26
chain:
    JSR $3307
    JSR $365A
    JSR $3E5B
    JSR $3320
    RTS
org $C0FF77
tick:
    SEP #$20
    JSL combo
    JSL sarachk
    BCC +
    LDA $124B
    JSR $3431
    JSR chain
+   RTS
org $C0FF40        ; free zeros in C0 (help_wait ends at $C0FF36)
ryo_strm:
    JSR $2FD8
    RTL
org $C004B6
    JSL ryo_nmi
    NOP
org $C031B7
    JSR chain
    JSR tick
    NOP #6

org $FE0200
getopt:            ; A8 in/out: A = opts (0 if signature invalid). SRAM is read only when the WRAM cache is invalid
    LDA.l !W         ; cache valid only if +0 = $A5 AND +3 = opts^$5A: power-on WRAM is not zeroed on real
    CMP #$A5         ; hardware (MiSTer fills a pattern), so a lone $A5 marker could accept garbage opts
    BNE .load
    LDA.l !W+1
    EOR #$5A
    CMP.l !W+3
    BNE .load
    LDA.l !W+1
    RTL
.load:
    LDA.l !S
    CMP #$54
    BNE .z
    LDA.l !S+1
    CMP #$44
    BNE .z
    LDA.l !S+2
    EOR #$A5
    CMP.l !S+3
    BNE .z
    LDA.l !S+2
    STA.l !W+1
    LDA #$01
    BRA .fin
.z: LDA #$00
    STA.l !W+1
.fin:
    STA.l !W+2
    LDA.l !W+1
    EOR #$5A
    STA.l !W+3
    LDA #$A5
    STA.l !W
    LDA.l !W+1
    RTL

setopt:            ; A8 in/out: A = opts to store. Writes SRAM signature + opts, refreshes WRAM cache.
    STA.l !W+1
    PHA
    LDA #$54
    STA.l !S
    LDA #$44
    STA.l !S+1
    PLA
    STA.l !S+2
    EOR #$A5
    STA.l !S+3
    LDA.l !W+1
    EOR #$5A
    STA.l !W+3
    LDA #$A5
    STA.l !W
    LDA.l !W+1
    RTL

turbo:             ; A8; returns carry = ($082C >= threshold)
    JSL getopt
    AND #$01
    BNE .t
    LDA $082C
    CMP #$04
    RTL
.t: LDA $082C
    CMP #$03
    RTL

sarachk:           ; A8; carry set -> do one extra step this tick. Any hero (was Sara only): step $0825 is 4 px
    LDA $0825        ; (Sara, Hornisse) or 8 px (Ryo); the extra step is the hero's own step size, so the boost is the
    CMP #$04         ; same +25/+50 % for everyone and the 4/8 px grid alignment and collision chain are unchanged
    BEQ .go
    CMP #$08
    BNE .no
    JSR .gate        ; Ryo: an 8 px step crosses one 8 px BG column/row, so two steps in one tick need two streamed
    BCC .no          ; columns but the game streams one per tick (C0:2FD8 -> one NMI DMA, C0:04B6). Issue #15: stream
    JSL ryo_pre      ; the normal step's column now into a second NMI slot (ryo_nmi), then take the extra step
    SEC
    RTL
.go:
    JSR .gate
    RTL
.no: CLC
    RTL
.gate:
    LDA $0829
    BNE .n
    JSL getopt
    LSR
    AND #$03
    CMP #$01
    BEQ .s5
    CMP #$02
    BEQ .s6
.n: CLC
    RTS
.s5: LDA $10C2
    AND #$03
    BNE .n
    SEC
    RTS
.s6: LDA $10C2
    LSR
    BCC .n
    SEC
    RTS

!Q = $306340      ; battery SRAM (no WRAM byte is safe: stage loads and the overlay's CGRAM save reuse $7ECF80+); +0 = $A7 when pending, +11 = DMA mask. issue #15 second column-DMA slot: +0 pending, +1 VMAIN, +2/3 VRAM addr ($006C), +4..+10 = $085E..$0864
ryo_pre:          ; A8. Run the game's streamer for the camera after the normal step; if it queued a column, move that
    PHP           ; job to slot !Q (NMI runs it before the game's own job) so the extra step's column can use $0081
    JSL ryo_strm
    SEP #$20
    LDA $0081
    BEQ +
    STA.l !Q+11
    LDA #$A7
    STA.l !Q
    LDA $00A9 : STA.l !Q+1
    LDA $006C : STA.l !Q+2
    LDA $006D : STA.l !Q+3
    LDA $085E : STA.l !Q+4
    LDA $085F : STA.l !Q+5
    LDA $0860 : STA.l !Q+6
    LDA $0861 : STA.l !Q+7
    LDA $0862 : STA.l !Q+8
    LDA $0863 : STA.l !Q+9
    LDA $0864 : STA.l !Q+10
    STZ $0081
+   PLP
    RTL

ryo_nmi:          ; replaces SEP #$20 : LDA $0081 at C0:04B6 (NMI column DMA); runs the queued slot first
    SEP #$20
    LDA.l !Q
    CMP #$A7
    BNE +
    LDA.l !Q+11
    PHA
    LDA.l !Q+1 : STA $2115
    REP #$20
    LDA.l !Q+2
    CLC
    ADC #$0800
    STA $2116
    LDA.l !Q+6 : STA $4342
    LDA.l !Q+9 : STA $4345
    SEP #$20
    LDA.l !Q+4 : STA $4340
    LDA.l !Q+5 : STA $4341
    LDA.l !Q+8 : STA $4344
    PLA
    STA $420B
    LDA #$00
    STA.l !Q
+   LDA $0081
    RTL

mon:
    PHP
    REP #$30
    PHA
    SEP #$20
    JSL getopt
    AND #$08
    REP #$20
    BEQ .out
    LDA $0004
    CMP #$0004
    BNE .out
    LDA $0000
    ORA $0002
    AND #$0007
    BNE .out
    LDA $10C2
    AND #$0003
    BNE .out
    LDA #$0008
    STA $0004
.out:
    PLA
    PLP
    REP #$20
    SEC              ; exact original exit flags: REP #$20 / CMP #$0000 leaves C=1
    RTL

; --- L+R held, then X = turbo, Y = hero speed, A = monsters, B = rumble off. Feedback: mosaic blinks (setting value + 1 blinks)
combo:
    PHP
    SEP #$20
if defined("HAS_SKIP")
    JSL sk_field            ; field tick: no script running -> skip mode off, Start edge tracker synced
endif
    ; issue #16: L+R+button DX option hotkeys retired (toggles live in Configuration)
    PLP
    RTL

joy:
    PHP
    SEP #$20
-   LDA $4212        ; wait for VBlank END like the original game (not just auto-joypad
    BMI -            ; busy): keeps the original NMI timing
    LDA $4219
    STA.l !W+11
    STA $0082
    LDA $4218
    STA.l !W+10
    STA $0083
    ; issue #16: no L+R face-hide; synthesize per-hero L/R shortcuts into $82/$83
    JSL lr_sc
    JML $C0050C

; ---- issue #16: per-hero L/R move shortcuts (P1). Pads: $82 = B Y Sel Start U D L R, $83 = A X L R.
; L = B+Y (Sara Star fall / Ryo Wall of fire) or Hornisse mash-B Sword frenzy; R = A+B; L+R = rotate then face btn.
; Raw shoulders stay in !W+10; game-visible $83 always has L/R cleared. P2 would mirror on $086E/$086F after C0050C.
lr_sc:
    PHP
    SEP #$20
    LDA $00F0
    BNE .strip
    LDA $1430
    BEQ .strip
    CMP #$04
    BCS .strip
    LDA $0083
    AND #$30              ; L=#$20 R=#$10
    CMP #$30
    BNE +
    JMP lr_spin
+   CMP #$20
    BNE +
    JMP lr_L
+   CMP #$10
    BNE +
    JMP lr_R
+   LDA #$00
    STA.l !W+12
    STA.l !W+13
.strip:
    LDA $0083
    AND #$CF              ; drop L/R so shoulders are dedicated to shortcuts
    STA $0083
    PLP
    RTL

lr_R:                     ; R -> A+B
    LDA #$01
    STA.l !W+13
    LDA #$00
    STA.l !W+12
    LDA $0082
    ORA #$80              ; B
    STA $0082
    LDA $0083
    AND #$CF
    ORA #$80              ; A
    STA $0083
    PLP
    RTL

lr_L:
    LDA $1430
    CMP #$01
    BEQ lr_mash           ; Hornisse: mash B
    LDA #$02
    STA.l !W+13
    LDA #$00
    STA.l !W+12
    LDA $0082
    ORA #$C0              ; B+Y
    STA $0082
    LDA $0083
    AND #$CF
    STA $0083
    PLP
    RTL

lr_mash:
    LDA.l !W+13
    CMP #$03
    BEQ +
    LDA #$00
    STA.l !W+12           ; fresh L press: restart pulse
+   LDA #$03
    STA.l !W+13
    LDA.l !W+12
    INC
    STA.l !W+12
    CMP #$06
    BCC +
    LDA #$00
    STA.l !W+12
+   LDA.l !W+12
    CMP #$02              ; frames 0-1: B down; 2-5: up (~10 taps/s)
    BCS +
    LDA $0082
    ORA #$80
    STA $0082
+   LDA $0083
    AND #$CF
    STA $0083
    PLP
    RTL

lr_spin:                  ; L+R: two rotate circles then face button (reliable vs one)
    LDA.l !W+13
    CMP #$04
    BEQ +
    LDA #$00
    STA.l !W+12           ; fresh L+R: restart
+   LDA #$04
    STA.l !W+13
    LDA $1430
    CMP #$03
    BNE +
    JMP lr_spin_ryo
+   ; Hornisse/Sara: 4-on/2-off x4 dirs x2 circles = 48, then 8 button (phase 0..55)
    LDA.l !W+12
    INC
    STA.l !W+12
    DEC A
    CMP #56
    BCC +
    LDA #$00
    STA.l !W+12
    LDA #$00
+   PHA
    JSR lr_spin_clear
    PLA
    CMP #48
    BCC .hs_dirs
    JMP lr_spin_btn
.hs_dirs:
    PHA
    LDA #$00
    STA.l !W+15           ; dir-step quotient
    PLA
-   CMP #6
    BCC .hs_sub
    SEC
    SBC #6
    PHA
    LDA.l !W+15
    INC
    STA.l !W+15
    PLA
    BRA -
.hs_sub:
    CMP #4                ; 0-3 hold dir, 4-5 gap
    BCC +
    JMP lr_spin_done      ; gap frame
+   LDA.l !W+15
    AND #$03
    JMP lr_spin_dir

lr_spin_ryo:              ; Ryo: 6-on/dir x4 x2 circles = 48, then 8 Y (phase 0..55).
                          ; Spin check N=2 (~8 frames max/dir); 6f/dir hits clones, 1f only fires Y.
    LDA.l !W+12
    INC
    STA.l !W+12
    DEC A
    CMP #56
    BCC +
    LDA #$00
    STA.l !W+12
    LDA #$00
+   PHA
    JSR lr_spin_clear
    PLA
    CMP #48
    BCC .ry_dirs
    JMP lr_spin_btn
.ry_dirs:
    PHA
    LDA #$00
    STA.l !W+15
    PLA
-   CMP #6
    BCC .ry_sub
    SEC
    SBC #6
    PHA
    LDA.l !W+15
    INC
    STA.l !W+15
    PLA
    BRA -
.ry_sub:
    LDA.l !W+15
    AND #$03
    JMP lr_spin_dir

lr_spin_clear:
    LDA $0082
    AND #$30              ; keep real Select/Start
    STA.l !W+14
    STZ $0082
    STZ $0083
    RTS

lr_spin_dir:              ; A = 0 R, 1 D, 2 L, 3 U
    CMP #$00
    BEQ .dr
    CMP #$01
    BEQ .dd
    CMP #$02
    BEQ .dl
    LDA.l !W+14
    ORA #$08
    STA $0082
    JMP lr_spin_done
.dr:
    LDA.l !W+14
    ORA #$01
    STA $0082
    JMP lr_spin_done
.dd:
    LDA.l !W+14
    ORA #$04
    STA $0082
    JMP lr_spin_done
.dl:
    LDA.l !W+14
    ORA #$02
    STA $0082
    JMP lr_spin_done

lr_spin_btn:
    LDA $1430
    CMP #$01
    BEQ .ba
    CMP #$02
    BEQ .bb
    LDA.l !W+14
    ORA #$40              ; Ryo Y
    STA $0082
    JMP lr_spin_done
.ba:
    LDA #$80              ; Hornisse A
    STA $0083
    LDA.l !W+14
    STA $0082
    JMP lr_spin_done
.bb:
    LDA.l !W+14
    ORA #$80              ; Sara B
    STA $0082
lr_spin_done:
    PLP
    RTL
