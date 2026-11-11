hirom
; ===== Trinea DX options (beta): runtime toggles stored in unused SRAM tail =====
; SRAM $30:6300 'T', $6301 'D', $6302 opts, $6303 opts^$A5   (invalid -> all OFF = original)
;   opts bit0 turbo (20 Hz logic), bits1-2 hero speed (0 orig, 1 = 5px-equiv, 2 = 6px-equiv), bit3 faster monsters,
;   bit4 RETIRED (was rumble off in afb92e1a/2339e2b8; ignored so saves that toggled it get rumble back),
;   bit5 rumble off (read by asm/rumble.asm rum_muted), bit6 RETIRED (was Start-skips-dialogue off via L+R+Select;
;   ignored and never written by a toggle, so saves that set it still skip),
;   bit7 RETIRED (was Select help overlay off via L+R+Start; ignored so saves that set it still get the overlay)
;   $6304 shortcuts: $01 = L/R shortcuts OFF (original shoulder input); any other value (incl. $00/$FF,
;   blank, or old saves that never wrote this byte) = ON. Not packed into $6302 so retired option bits
;   in old saves cannot turn shortcuts off. Does not touch $7ECF1E (rumble) or $7ECF1F (L+R facing).
; scratch (prev buttons, feedback ticks, saved mosaic, raw pad) lives in WRAM !W+4..+11, not SRAM: SRAM is only read when
; the WRAM cache is invalid and only written when a toggle changes (issue #4 real-hardware hardening)
!S = $306300
!W = $7ECF10      ; WRAM cache/scratch (hw fix #4): +0 $A5 = cache valid, +1 opts, +2 sig valid, +3 opts^$5A (cache check), +4..+11 pad/feedback scratch
                  ; +12 L/R timer, +13 L/R mode (0 idle, 1 R-debounce, 2 L-debounce, 3 Hornisse mash,
                  ;   4 R-pulse, 5 L+R commit, 6 cancel-wait, 7 L-pulse, 8 L+R firing, 9 post-fire wait).
                  ;   +15 facing captured at L+R press.
                  ;   Do not use +14: $7ECF1E is rumble.asm !R_ACC (leaky bucket) and would decay the facing.

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
org $C0FF44        ; still unused zeros after ryo_strm
c0_jsr8707:
    JSR $8707      ; native spin check must JSR from bank C0 (RTS), not from FE
    RTL
org $C088E0        ; was LDA #$0002 / JSR $8707 (6 bytes) — Ryo N=2
    JSL spin_hook
    NOP
    NOP
org $C086CA        ; was LDA #$0006 / JSR $8707 — Hornisse/Sara copy
    JSL spin_hook6
    NOP
    NOP
org $C087E9        ; was LDA #$0006 / JSR $8707 — Hornisse/Sara copy
    JSL spin_hook6
    NOP
    NOP
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

getsc:             ; A8 in/out: A = 1 if L/R shortcuts are OFF, else 0.
    LDA.l !S+4       ; $01 is the only OFF sentinel, so $00/$FF/garbage and pre-toggle saves stay ON
    CMP #$01
    BEQ .off
    LDA #$00
    RTL
.off:
    LDA #$01
    RTL

setsc:             ; A8 in: A = 0 (ON) or 1 (OFF). Writes only $6304; does not alter the TD opts block.
    AND #$01
    STA.l !S+4
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
; L = B+Y (Sara Star fall / Ryo Wall of fire) or Hornisse mash-B Sword frenzy; R = A+B.
; L+R = ~0.5s commit (30 joy/NMI frames, not turbo-shortened) then the native face button, with the
; C0:88E0 spin check bypassed. No synthetic D-pad 360. Facing $1437 is captured at L+R press and
; restored through the delay and at fire so the special uses that direction (fixes Sara LEFT->NORTH
; from the old sequencer ending on Up). Game-visible $83 always has L/R cleared.
; Raw shoulders stay in !W+10; P2 would mirror on $086E/$086F after C0050C.
; Configuration "Shortcuts" OFF ($6304=$01): skip all of this and leave $82/$83 as the raw pad so
; L/R do exactly what they did in the original game (no injected specials, no gold spent).
lr_sc:
    PHP
    SEP #$20
    JSL getsc
    BEQ .go
    LDA #$00
    STA.l !W+12
    STA.l !W+13
    PLP
    RTL
.go:
    LDA $00F0
    BNE .to_reset             ; script/menu: drop any pending commit
    LDA $1430
    BEQ .to_reset
    CMP #$04
    BCS .to_reset
    LDA $0083
    AND #$30                  ; L=#$20 R=#$10
    CMP #$30
    BEQ .both
    CMP #$20
    BNE +
    JMP .lonly
+   CMP #$10
    BNE +
    JMP .ronly
+   ; both shoulders up: finish a pending single tap, else idle
    JMP .released
.to_reset:
    JMP .strip_reset

.both:
    LDA.l !W+13
    CMP #$09                  ; post-fire: no repeat until both release
    BNE +
    JMP .strip
+   CMP #$06                  ; cancelled chord
    BNE +
    JMP .strip
+   CMP #$08
    BEQ .firing
    CMP #$05
    BEQ .commit_tick
    CMP #$04                  ; single already firing: do not also start L+R
    BNE +
    JMP .strip
+   CMP #$07
    BNE +
    JMP .strip
+   CMP #$03
    BNE +
    JMP .strip
+   ; first frame both shoulders are down (or debounce upgraded to a chord): latch facing now
    LDA #$05
    STA.l !W+13
    LDA #$00
    STA.l !W+12
    LDA $7E1437
    STA.l !W+15
    JMP .commit_hold

.commit_tick:
    LDA.l !W+12
    INC
    STA.l !W+12
    CMP #30                   ; ~0.50s at ~60.1 Hz NMI/joy; turbo only shortens C0:0268 logic ticks
    BCC .commit_hold
    LDA #$00
    STA.l !W+12
    LDA #$08                  ; fire: hold native face button ~8 frames (old synth did the same)
    STA.l !W+13
.firing:
    LDA.l !W+12
    CMP #8
    BCC +
    LDA #$09
    STA.l !W+13
    JMP .strip
+   INC
    STA.l !W+12
    LDA.l !W+15
    STA $7E1437               ; restore facing from L+R press
    LDA $0082
    AND #$F0                  ; drop D-pad so movement cannot overwrite facing this frame
    STA $0082
    JMP lr_spin_btn

.commit_hold:
    LDA.l !W+15
    STA $7E1437               ; keep captured facing through the half-second delay
    LDA $0082
    AND #$F0
    STA $0082
    JMP .strip

; Release with no other shoulder: a brief L or R tap that never reached the
; 3-frame chord window still fires once. The synthetic combo is held for 8
; frames (same length as the L+R face-button pulse) so the game can see it
; after the physical shoulder is already up. L+R commit/cancel timing is
; unchanged: releasing from mode 5/6/8/9 never becomes a single shortcut.
.released:
    LDA.l !W+13
    CMP #$01
    BEQ .tap_R                ; R debounce: fire on release
    CMP #$02
    BEQ .tap_L
    CMP #$04
    BEQ .r_hold_or_done
    CMP #$07
    BEQ .l_hold_or_done
    CMP #$03
    BEQ .mash_tail
    JMP .strip_reset
.tap_R:
    JMP lr_R
.tap_L:
    JMP lr_L
.r_hold_or_done:
    LDA.l !W+12
    CMP #8
    BCC +
    JMP .strip_reset          ; pulse finished and R is up
+   JMP lr_R
.l_hold_or_done:
    LDA.l !W+12
    CMP #8
    BCC +
    JMP .strip_reset
+   JMP lr_L
.mash_tail:
    LDA.l !W+12
    CMP #16                   ; keep auto-mash going long enough for frenzy to start
    BCC +
    JMP .strip_reset
+   JMP lr_mash

.lonly:
    LDA.l !W+13
    CMP #$05
    BNE +
    JMP .cancel               ; dropped R during commit: no fire, no leftover L shortcut
+
    CMP #$06
    BNE +
    JMP .strip
+   CMP #$08
    BNE +
    JMP .strip
+   CMP #$09
    BNE +
    JMP .strip
+   CMP #$04                  ; R pulse already running: do not also start L
    BNE +
    JMP .strip
+   CMP #$03
    BEQ .do_L                 ; Hornisse mash already running
    CMP #$07
    BEQ .do_L                 ; L pulse already running
    CMP #$02
    BEQ .ldeb_tick
    LDA #$02
    STA.l !W+13
    LDA #$00
    STA.l !W+12
    JMP .strip
.ldeb_tick:
    LDA.l !W+12
    INC
    STA.l !W+12
    CMP #$03                  ; ~3-frame chord debounce so a sloppy L+R does not fire L first
    BCS .do_L
    JMP .strip
.do_L:
    JMP lr_L

.ronly:
    LDA.l !W+13
    CMP #$05
    BEQ .cancel
    CMP #$06
    BNE +
    JMP .strip
+   CMP #$08
    BNE +
    JMP .strip
+   CMP #$09
    BNE +
    JMP .strip
+   CMP #$07
    BNE +
    JMP .strip
+   CMP #$03
    BNE +
    JMP .strip
+   CMP #$04
    BEQ .do_R
    CMP #$01
    BEQ .rdeb_tick
    LDA #$01
    STA.l !W+13
    LDA #$00
    STA.l !W+12
    JMP .strip
.rdeb_tick:
    LDA.l !W+12
    INC
    STA.l !W+12
    CMP #$03
    BCS .do_R
    JMP .strip
.do_R:
    JMP lr_R

.cancel:
    LDA #$06
    STA.l !W+13
    JMP .strip

.strip_reset:
    LDA #$00
    STA.l !W+12
    STA.l !W+13
.strip:
    LDA $0083
    AND #$CF                  ; drop L/R so shoulders are dedicated to shortcuts
    STA $0083
    PLP
    RTL

; R -> A+B, held for at least 8 frames even if the shoulder is already up.
lr_R:
    LDA.l !W+13
    CMP #$04
    BEQ +
    LDA #$00
    STA.l !W+12
    LDA #$04
    STA.l !W+13
+   LDA.l !W+12
    CMP #8
    BCS +
    INC
    STA.l !W+12
+   LDA $0082
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
    LDA.l !W+13
    CMP #$07
    BEQ +
    LDA #$00
    STA.l !W+12
    LDA #$07
    STA.l !W+13
+   LDA.l !W+12
    CMP #8
    BCS +
    INC
    STA.l !W+12
+   LDA $0082
    ORA #$C0              ; B+Y
    STA $0082
    LDA $0083
    AND #$CF
    STA $0083
    PLP
    RTL

; Hornisse mash: same 2-on / 4-off pattern (~10 taps/s), but !W+12 is a
; total-frame count (no wrap) so a short L tap can keep auto-mashing after
; release. B is down when (count % 6) <= 1, which matches the old wrap cycle.
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
    SEC
.mod6:
    SBC #$06
    BCS .mod6
    ADC #$06              ; A = count % 6
    CMP #$02              ; 0-1: B down; 2-5: up
    BCS +
    LDA $0082
    ORA #$80
    STA $0082
+   LDA $0083
    AND #$CF
    STA $0083
    PLP
    RTL

lr_spin_btn:              ; inject the native rotate-move face button (no D-pad sequence)
    LDA $1430
    CMP #$01
    BEQ .ba
    CMP #$02
    BEQ .bb
    LDA $0082
    AND #$F0
    ORA #$40              ; Ryo Y
    STA $0082
    JMP .btn_done
.ba:
    LDA $0083
    AND #$CF
    ORA #$80              ; Hornisse A
    STA $0083
    LDA $0082
    AND #$F0
    STA $0082
    JMP .btn_done
.bb:
    LDA $0082
    AND #$F0
    ORA #$80              ; Sara B
    STA $0082
.btn_done:
    LDA $0083
    AND #$CF
    STA $0083
    PLP
    RTL

; Bypass C0:8707 while mode 8 (firing) so L+R does not need a 360; a real D-pad spin still uses 8707.
spin_hook:                 ; native N=2 (Ryo)
    PHP
    SEP #$20
    LDA.l !W+13
    CMP #$08
    BEQ spin_bypass
    PLP
    LDA #$0002
    JSL c0_jsr8707
    RTL
spin_hook6:                ; native N=6 (Hornisse/Sara)
    PHP
    SEP #$20
    LDA.l !W+13
    CMP #$08
    BEQ spin_bypass
    PLP
    LDA #$0006
    JSL c0_jsr8707
    RTL
spin_bypass:
    REP #$20
    LDA #$0001
    STA $1540
    LDA #$0002
    STA $1542
    LDA #$0004
    STA $1544
    LDA #$0008
    STA $1546
    PLP
    RTL
