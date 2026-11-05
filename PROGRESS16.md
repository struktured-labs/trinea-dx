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
- Sound Test shows SFX/BGM prefix + number via D9 stub → `$9A9B` (restored in follow-up #2).
- Exit A: brief black then title (same on pristine te-bug); turbo persists across reopen (`cfg_persist_turbo_row.png`).
- Shots: `cfg_step3_open.png`, `cfg_turbo_on.png`, `cfg_foes_on.png`, `cfg_hero_faster.png`, `cfg_rumble_off.png`, `cfg_stest_*`, `cfg_persist_*`, `cfg_back_title.png`.
- Commit: `81d1ec5`.

### 4. Retire L+R hotkeys; update Select Controls overlay
- `combo`: hotkey body removed (sk_field only). Joy keeps raw pad in `!W+10/11` but no longer hides face/Select while L+R held.
- `helpgfx.py`: L/R labels are per-hero shortcuts (Hornisse Sword frenzy / Morning star; Sara Star fall / Homing flame; Ryo Wall of fire / Bombs); tip `{L}/{R}: shortcuts` + `{L+R}: rotate move`; `help_lr.bin` blank stub; `h_lr` immediate RTS.
- Headless: pristine L+R+X writes opts `544401a4`; dx-issue16 stays `ffffffff`. Overlay open + L+R held keeps face/shortcut labels (no DX-opts swap).
- Shots: `step4_overlay_hi.png`, `step4_overlay_lr_hi.png`, `help_{horn,sara,ryo}_step4.png`, `step4_pristine_lrx.png`.
- Build md5 (ROM, step4): `c51a1dc99fbd42ce2b126486b5457a1d`.

### 5. Per-hero L/R shortcuts
- `lr_sc` in `asm/options.asm` (from `joy`): pads `$82`=B Y Sel Start UDLR, `$83`=A X L R; always strip L/R from game `$83`.
- L: Hornisse mash-B pulse (2 on / 4 off); Sara/Ryo B+Y. R: A+B. L+R: two D-pad circles then face button (Hornisse/Sara 4-on/2-off; Ryo 1-frame/dir). Scratch `!W+12..+15`. P2 stub: would mirror on `$086E/$086F` after `C0050C`.
- Headless: Sara L→act `$1431`=60, R→homing, L+R→64 gold 100→90; Hornisse L→mash frenzy, R→morning star, L+R→lightning gold 90.
- Ryo real state (`smoke2_loc`→skip dialogue→`ryo_field.st`, hero=3): L→act 61 wall of fire, R→act 65 bombs, L+R→act 52 shadow clones gold 100→90.
- Ryo L+R spin fixed to 6 frames/dir ×4 ×2 circles then Y (1-frame/dir only fired Y; N=2 spin check needs ~6f).
- Docs: `docs/MOVES.md`, `README.md`, `CHANGELOG.md` (Unreleased).
- Shots: `step5_sara_{l,r,lr}.png`, `step5_horn_{l,r,lr}.png`, `step5_ryo_{l,r,lr}.png`.
- Build md5 (ROM, post-Ryo fix): `a4c753a75057fe51cebd4770bc6828cc`.

## Follow-ups (pre-Carmelo)
1. ~~Ryo real-state L/R/L+R~~ Done (`943679a`).
2. ~~Sound Test number display~~ Done (`16e195e`).
   - D9 stub `cfg_jsr_num` → `$9A9B`; digit at `$0638` (after SFX/BGM at `$062C`).
   - Blank `$0634..$0638` before draw (`$9A9B` skips leading zeros and writes right-to-left; without blank, tens digit goes stale on 0–9).
   - Verified: SFX15, BGM0, BGM3, back to SFX15. Shots `cfg_stest_num15/bgm0/bgm3/back_sfx.png`.
3. ~~Full regression savestate suite~~ Done.
   - Idle suite vs v1.1.3 (`f56777f3…`): **36/36** pixel-identical after 8 frames (`/tmp/reg16/report.json`).
   - Expected behavioral diffs only:
     - Title labels (LOAD/NEW/OPTIONS): ~0.4–0.9% pixel diff on title savestates.
     - Config menu: ~5.1% diff (`cfg_new` vs `cfg_old`).
     - L+R+X: v1.1.3 writes opts `544401a4` (turbo); dx-issue16 stays `ffffffff` (hotkeys retired).
   - L/R shortcuts re-verified on real field states (not poked `$1430`):
     - Ryo `ryo_field.st`: L→act 61 wall of fire, R→act 65 bombs, L+R→act 52 clones gold 100→90.
     - Sara `horn_field.st`: L→act 49, R→act 73.
     - Hornisse: prior `step5_horn_*` shots; no idle-horn savestate in suite this pass.
   - Overlay Select probe on town `ryo_field` skipped (HB `$7E8000` busy; help only opens in stages). Overlay label change already covered by step4 shots — not an unintended idle-suite diff.
   - No unintended gameplay diffs; no code fix required.
4. ~~Fresh SRAM defaults + v1.1.3 opts carry-over~~ Done.
   - Fresh / blank / `$FF` SRAM (no `TD` block): `getopt` → opts `0` → Turbo/Fast foes/Hero Speed Off, **Rumble On**. Shot `cfg_fresh_defaults.png`.
   - Existing v1.1.3-style block `TD` + opts `$2B` (turbo|hero Fast|foes|rumble off) + xor: carried into config UI (Turbo On, Fast foes On, Hero Speed Fast, Rumble Off). Shot `cfg_carry_v113.png`.
5. ~~Rebuild IPS/ROM md5s~~ Done.
   - `build/trinea_dx.ips` md5 `d742041e0d02c399c78b43589bd1364c`
   - `build/trinea_dx.sfc` / `rom/Trinea DX.sfc` md5 `0c0212d18d023426d898c7506010b141`
6. Deploy NEW file to rivalmage (no launch).

## Next
- P2 L/R shortcuts (structure noted; not implemented).
- Release notes when cutting v1.1.4.

## Notes
- Local only aside from rivalmage deploy (item 6); no push / GitHub / public comments.
- Headless bsnes-mercury via `tools/py/lr.py` (+ `tools/libretro/` core copy).
- dp `$20` is not a durable title selection store; use `!TM_SEL`.
- Always `cp` Japan ROM before asar (asar on already-patched ROM double-applies).
