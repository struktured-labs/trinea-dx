; #13 Play Level fix.
; Vanilla C1:43C3 doubled the player's damage to enemies on every level EXCEPT Easy, so Easy halved
; the player's attack and changed nothing else. Easy is supposed to make the player take less damage.
;  - Player damage to enemies: always the Normal (doubled) value.
;  - Enemy contact (C1:04A2) and projectile (C1:52AA) damage, set when the enemy spawns:
;    Easy = halved (min 1 if nonzero), Normal = unchanged, Hard = doubled, clamped at $FF (vanilla wrapped at base >= $80).
org $C143C3
    db $80,$05                ; BRA +5 -> C1:43CA; always take the Normal path (was: LDA $10BF : CMP #0 : BEQ skip-double)
org $C104A2
    JSL diff_contact
    NOP #10                   ; -> C104B0
org $C152AA
    JSL diff_proj
    NOP #12                   ; -> C152BA
org $FE0800
diff_contact:
    PHP : SEP #$20
    LDA $7E10BF : BEQ .easy
    CMP #$02 : BNE .done
    LDA $0023,x : ASL : BCC + : LDA #$FF
+   STA $0023,x : BRA .done
.easy
    LDA $0023,x : BEQ .done
    LSR : BNE + : INC
+   STA $0023,x
.done
    PLP : RTL
diff_proj:
    PHP : SEP #$20
    LDA $7E10BF : BEQ .easy
    CMP #$02 : BNE .done
    LDA $00000F,x : ASL : BCC + : LDA #$FF
+   STA $00000F,x : BRA .done
.easy
    LDA $00000F,x : BEQ .done
    LSR : BNE + : INC
+   STA $00000F,x
.done
    PLP : RTL
