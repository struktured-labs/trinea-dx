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
- Commits: `a4abab4` (WIP font/spawn), *(this commit)*.

## Next

3. Config rows: Turbo / Fast foes / Hero Speed / Rumble via getopt/setopt; persist; optional Sound Test nest.
4. Retire L+R hotkeys; update Select Controls overlay.
5. Per-hero L/R shortcuts (P1; structure for P2). Hornisse L = mash Sword Frenzy ([pt496u]).
- Docs + IPS/ROM md5s + regression savestates.

## Notes
- Local only; no push / GitHub / rivalmage / OBS.
- Headless bsnes-mercury via `tools/py/lr.py`.
- dp `$20` is not a durable title selection store; use `!TM_SEL`.
