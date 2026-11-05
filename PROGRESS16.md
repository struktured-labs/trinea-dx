# Issue #16 progress

Branch: `dx-issue16` (from `dx-bugfixes` / v1.1.3 @ 58b6a1c)
Worktree: `/workspace/te-16`
Screenshots: `/workspace/issue16/impl/`

## Done

### Step 1 (partial) — Title labels LOAD GAME / NEW GAME
- Redrew title font CHR (`asm/bin/titlefont.bin`) in existing style; bottoms at +16; FI map with blank at slot 9; unused C → pristine O.
- Font DMA on channel 7 during vblank + force blank; restore INIDISP `#$0F` (never read write-only `$2100`).
- Labels centered, Y stack 136/154/172.
- Highlight attrs paint (`$2C00` / `$2A00`); LOAD GAME bright on spawn.
- Screenshots: `title_v12.png`, `crop_v12.png` — glyphs correct and bright.

### Step 2 (partial) — OPTIONS entry
- Third row OPTIONS in vertical stack; Select still opens Configuration (`title_v12_cfg_select.png`).
- Start→OPTIONS hook present (`JML $CE3326`) but **nav selection not sticky yet**.

## In progress / blocked

- **Title nav / selection:** `$20` via `STA $20` is direct-page; value not surviving. Attrs sometimes paint wrong rows (NEW+OPTIONS both bright). Next: keep selection in `$7ECF30` with long addressing; fix 16-bit index TAX; verify Up/Down + Start on OPTIONS.
- Hooks: spawn `$CE3539`, count PEA `$CE34EE`, nav `$CE3382` → drawall `$34D5`, start `$CE336F`.

## Not started

3. Config rows: Turbo / Fast foes / Hero Speed / Rumble via getopt/setopt; persist; optional Sound Test nest.
4. Retire L+R hotkeys; update Select Controls overlay.
5. Per-hero L/R move shortcuts (P1 now, structure for P2); Hornisse L = mash Sword Frenzy per [pt496u].
- Docs: MOVES.md, README controls, CHANGELOG unreleased.
- IPS + ROM md5s; regression savestates.
- Local commits per step; no push / no GitHub comments.

## Deviations / notes

- CloudAgent unavailable → local impl.
- Do not touch rivalmage, saves, OBS.
- Emulators headless only (`tools/py/lr.py` + bsnes-mercury).
