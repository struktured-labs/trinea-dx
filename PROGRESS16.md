# Issue #16 progress

Branch: `dx-issue16` (from `dx-bugfixes` / v1.1.3 @ 58b6a1c)
Worktree: `/workspace/te-16`
Screenshots: `/workspace/issue16/impl/`

## Done

### 1. Title labels — LOAD GAME / NEW GAME
- Font CHR redrawn (`asm/bin/titlefont.bin`), DMA ch7 during vblank, INIDISP `#$0F`.
- Centered labels, Y 136/154/172; highlight `$2C00`/`$2A00`.
- Shot: `title_step1.png`, `nav5_*_crop.png`.

### 2. OPTIONS entry
- Vertical stack LOAD GAME / NEW GAME / OPTIONS.
- Nav via `$A9` edges (Up/Left, Down/Right); selection in `$7ECF30` (`!TM_SEL`).
- Start on OPTIONS → Configuration (`title_options_confirm.png`); Select still works (`opt_via_select.png`).
- Commits: `a4abab4` (WIP font/spawn), `4031c16`.

### 3. Config menu DX toggles
- New file `asm/configmenu.asm`; `setopt` in `asm/options.asm`; `incsrc` from `main_dx.asm`.
- Rows: Exit / Play Level / Sound Mode / Turbo / Fast foes / Hero Speed / Rumble / Sound Test.
- Sound Effects + Music Play nested under Sound Test (A toggles SFX↔BGM via `!CFG_MODE=$7ECF32`).
- L/R on Turbo/Fast foes/Rumble flip bits; Hero Speed cycles Off→Fast→Faster; getopt/setopt + SRAM `$306300` persist.
- Hooks: max `CMP #$07`; Right/Left at `$D99159`/`$D991CB` (game JMPs there, not `$9158`/`$91CA`); draw `$924D`; confirm `$9097`; D9 stubs for `$9A22`/`$922F`.
- Sound Test shows SFX/BGM prefix only (no digit via `$9A9B` — blacked out when called from EB path).
- Exit A: brief black then title (same on pristine te-bug); turbo persists across reopen (`cfg_persist_turbo_row.png`).
- Shots: `cfg_step3_open.png`, `cfg_turbo_on.png`, `cfg_foes_on.png`, `cfg_hero_faster.png`, `cfg_rumble_off.png`, `cfg_stest_*`, `cfg_persist_*`, `cfg_back_title.png`.
- Commit: `81d1ec5`.

### 4. Retire L+R hotkeys; update Select Controls overlay
- `combo`: hotkey body removed (sk_field only). Joy keeps raw pad in `!W+10/11` but no longer hides face/Select while L+R held.
- `helpgfx.py`: L/R labels are per-hero shortcuts (Hornisse Sword frenzy / Morning star; Sara Star fall / Homing flame; Ryo Wall of fire / Bombs); tip `{L}/{R}: shortcuts` + `{L+R}: rotate move`; `help_lr.bin` blank stub; `h_lr` immediate RTS.
- Headless: pristine L+R+X writes opts `544401a4`; dx-issue16 stays `ffffffff`. Overlay open + L+R held keeps face/shortcut labels (no DX-opts swap).
- Shots: `step4_overlay_hi.png`, `step4_overlay_lr_hi.png`, `help_{horn,sara,ryo}_step4.png`, `step4_pristine_lrx.png`.
- Build md5 (ROM): `c51a1dc99fbd42ce2b126486b5457a1d`.

## Next

5. Per-hero L/R shortcuts (P1; structure for P2). Hornisse L = mash Sword Frenzy ([pt496u]); R = A+B-class; L+R = rotate+button.
- Docs (MOVES/README/CHANGELOG) + IPS/ROM md5s + regression savestates.

## Notes
- Local only; no push / GitHub / rivalmage / OBS.
- Headless bsnes-mercury via `tools/py/lr.py` (+ `tools/libretro/` core copy).
- dp `$20` is not a durable title selection store; use `!TM_SEL`.
- Always `cp` Japan ROM before asar (asar on already-patched ROM double-applies).
