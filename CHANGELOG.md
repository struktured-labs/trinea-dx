# Changelog

## Unreleased (issue #16)
- Title menu: LOAD GAME / NEW GAME / OPTIONS (was CONTINUE/START); Start on OPTIONS opens Configuration.
- Configuration menu: Turbo, Fast foes, Hero Speed, Rumble rows (plus nested Sound Test); opts persist in SRAM $30:6300.
- Retired field L+R+button DX option hotkeys; Select overlay no longer swaps to "L+R: DX opts".
- Per-hero L/R move shortcuts (P1): L/R synthesize specials; L+R plays the rotate move. Hornisse L = mash Sword Frenzy.

## v1.1.3 (2026-11-01)
- Fixed: Play Level Easy (Configuration menu) halved the damage YOU dealt and left damage taken unchanged, because the original code at C1:43C3 doubles hero attack on every level except Easy. Easy now deals Normal damage and halves enemy contact/projectile damage to the hero (min 1). Hard still doubles enemy damage, now clamped at 255 instead of wrapping for base values of 128 or more. Normal is unchanged (#13). The hidden Configuration menu opens with Select on the title screen's CONTINUE/START.
- Fixed: Ryo's shadow clones were documented as a "slow" spin (Select overlay, README, MOVES). The game (C0:88E0 -> C0:8707) requires a FAST spin for Ryo: each direction held under 2 input samples (~8 frames) vs 6 for Hornisse and Sara. Overlay now reads "Spin D-pad (fast) then Y".
- Fixed: Hero speed barely affected Ryo once the screen scrolled (+6% instead of +25/+50%). His extra 8 px step now streams the skipped BG column/row through a second NMI DMA slot, so fast/faster give ~+29%/+40% in Neo Edo with no garbled columns (#15).

## v1.1.2 (2026-10-31)
- Fixed: Select controls overlay text shifted sideways / wavy in stages using BG3 horizontal-scroll HDMA (e.g. Neo Edo). Overlay HDMA channel 6 now writes BG3HOFS=0 as well as BG3VOFS on every line (mode 3), so the stage's own scroll HDMA can no longer latch an offset under the page (#12).

## v1.1.1 (2026-10-28)
- Removed the L+R+Select dialogue-skip toggle (undocumented in the game). Start always skips dialogue, including on saves that had it off (opts bit6 ignored, never written); L+R+Select does nothing.

## v1.1 (2026-10-27): Trinea DX
- Speed improvements: perf patch plus optional turbo, faster monsters, and hero speed (any hero; mainly to bring Sara up to her Game Boy speed).
- Options menu: hold L+R in the field, then X turbo / Y hero speed / A faster monsters / B rumble off / Select dialogue skip / Start help overlay. Saved in SRAM.
- RumbleShock rumble, on by default.
- Select controls overlay: pad diagram plus each hero's moves, in the ending-logo colors (Hornisse blue, Sara green, Ryo pink). Hornisse A = "Overhead", Y = "Low sweep". Holding L+R shows the DX option buttons.
- Start skips dialogue (default on). Staff roll credits the translation and Trinea DX.
- Fixed: final-boss hard freeze. Rumble hooks ran with X/Y 8-bit, and an NMI landing in them crashed in the game's palette effect. 0 freezes in 45 soak runs vs ~2 in 39 before.
- Fixed: rumble stuck on or pulsing endlessly; no rumble during the title demo.
- Wizard spelled "Graph" consistently; opening line (OPEN_28) fix; Ryo-scenario text polish.

## v1.0.1 (2026-10-13)
- Fixed: dialogue text corrupted the stage collision map.

## v1.0 (2026-09-26)
- First public release: complete English translation.
