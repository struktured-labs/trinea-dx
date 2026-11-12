===============================================================================
                    TRINEA DX v1.2.2 - English Translation + DX
                          by struktured labs
===============================================================================

Game:          Trinea
Platform:      Super Nintendo / Super Famicom
Genre:         Action RPG
Original:      Yanoman / Japan Art Media (JAM), 1993 (Japan only)
Patch version: 1.2.2
Release date:  2026-11-12
Status:        Complete
Project:       Trinea DX (enhancement project; v1.0 = English translation)
Source:        https://github.com/struktured-labs/trinea-dx

-------------------------------------------------------------------------------
 CONTENTS
-------------------------------------------------------------------------------
 1. About
 2. ROM information
 3. How to apply the patch
 4. Controls and options
 5. Known issues
 6. Credits
 7. License
 8. Changelog

-------------------------------------------------------------------------------
 1. ABOUT
-------------------------------------------------------------------------------
Trinea is an overhead action RPG with three playable heroes, each with a
separate scenario: the masked knight Hornisse, the winged fire-wielder Sara
Weathers, and the Neo Edo ninja Tetsuya "Ryo" Mifune. This patch translates
the entire game into English:

 - All 841 script strings in all three scenarios: dialogue, choices,
   narration, the opening and ending cutscenes and the character profiles.
 - The character select screen, shop descriptions and messages, and the
   money label.
 - A new variable-width dialogue font and additions to the 8x8 small font.
 - DX extras (v1.2.2): less of the original game's slowdown in some
   scenes; a title LOAD GAME / NEW GAME / OPTIONS menu; a Configuration
   menu (Game Speed, Enemy Speed, Hero Speed, Rumble, L/R Shortcuts, plus a nested
   Sound Test); per-hero L/R move shortcuts (optional; off restores the
   original shoulder buttons); RumbleShock rumble; a Select controls
   overlay; Start to skip dialogue; and a boot splash. Every toggle can
   be switched off; the overlay only appears when you press Select, and
   Start skips dialogue only when you press it.
 - The ROM is expanded to 32 Mbit (4 MB HiROM) with a valid checksum.

This build was smoke-tested on MiSTer on 2026-11-12. v1.2.1 and earlier
were hardware-tested on MiSTer.

-------------------------------------------------------------------------------
 2. ROM INFORMATION
-------------------------------------------------------------------------------
Apply the patch to this ROM (No-Intro), headerless:

  File:   Trinea (Japan).sfc
  Size:   2,097,152 bytes (16 Mbit), NO 512-byte copier header
  CRC32:  C20419EC
  MD5:    8622B25466D1CF31E8A8771838B02CA7
  SHA-1:  BA4866A599C9DC380C11F0CB3C1F8E0374D35DFF

After patching:

  Size:   4,194,304 bytes (32 Mbit)
  CRC32:  D4982588
  MD5:    CE0C954D52F57214B425A9A9F74E6EED
  SHA-1:  1679EA7E02FAD41AE87622A8E82C904EAA66CF47

-------------------------------------------------------------------------------
 3. HOW TO APPLY THE PATCH
-------------------------------------------------------------------------------
 1. Make a backup copy of your ROM and check it against the hashes above.
    If your file is 2,097,664 bytes, it has a copier header. Remove the
    header first.
 2. Apply "Trinea (Japan) [T-En DX by struktured labs v1.2.2].ips" with an IPS
    patcher, for example:
      - Floating IPS (Flips)   https://github.com/Alcaro/Flips
      - ROM Patcher JS (web)   https://www.marcrobledo.com/RomPatcher.js/
      - Lunar IPS
 3. Check that the patched ROM matches the "After patching" hashes.

Emulators that soft-patch IPS files (RetroArch, snes9x, bsnes) can load the
patch if it has the same name as the ROM and sits next to it.

MiSTer, flash carts (SD2SNES/FXPak, EverDrive) and other hardware: patch the
ROM on a PC first and copy the patched .sfc to the device. Do not rely on
soft-patching. The patched game is a plain 32 Mbit HiROM with no special chips.

-------------------------------------------------------------------------------
 4. CONTROLS AND OPTIONS
-------------------------------------------------------------------------------
 Select   In the field or a stage, shows a pad diagram with button actions
          (including L/R shortcuts) and your hero's moves (Hornisse blue,
          Sara green, Ryo pink). Press Select or Start to close it.
 Start    On the title screen, confirms LOAD GAME / NEW GAME / OPTIONS.
          On OPTIONS it opens Configuration. While text is showing, skips
          the rest of the scene's dialogue from the next prompt on, always.
          L+R+Start is a plain Start (pause). Story flags, map moves and
          battles still happen.

 Title menu: LOAD GAME / NEW GAME / OPTIONS. Start (or Select) on OPTIONS
 opens Configuration. Moving the title cursor resets the ~10s attract
 idle timer, so you can walk down to OPTIONS without the demo starting.

 Configuration (saved in SRAM):
   Game Speed     Normal / Turbo
   Enemy Speed    Normal / Fast
   Hero Speed     Normal / Fast / Faster. Works for any hero, but it
                  is mainly there to bring Sara up to the speed she
                  had in the Game Boy version.
   Rumble         On by default (Off / On).
   L/R Shortcuts  On by default. Off disables all DX L/R hero
                  shortcuts (single L, single R, and L+R) and
                  restores original shoulder input: no injected
                  specials and no gold spent.
   Sound Test     Nested under Configuration.
  The option cycles and saved settings are the same as v1.2.1.
 The old field L+R+button DX option hotkeys are retired.

 L/R shortcuts (when L/R Shortcuts is On):
   L / R fire each hero's specials:
     Hornisse: L = mash Sword Frenzy (original buildup, not instant),
               R = morning star
     Sara:     L = star fall, R = homing flame
     Ryo:      L = wall of fire, R = bombs
   Hold L+R about 0.5 seconds to fire the rotate special in the facing
   you had when you pressed them (Hornisse lightning, Sara Dragon Fire,
   Ryo shadow clones). Release either shoulder during that window to
   cancel; that chord will not fire L or R. Original gold costs still
   apply. Native spin-then-button input is unchanged.

 Moves (full list in docs/MOVES.md in the source repository):
 - X special: only X spends it. You start with 1 and can hold up to 5.
 - Rotate moves cost 10% of your gold (min 10G). A+B moves are free.
 - Hornisse: A = Overhead, Y = Low sweep; mash B for the sword frenzy;
   A+B morning star; rotate the D-pad then A for lightning.
 - Sara: rotate then B for Dragon Fire; B+Y star fall; A+B homing flame.
 - Ryo: rotate fast then Y for shadow clones; B+Y wall of fire;
   A+B bombs.

 Rumble works with RumbleShock-style pads on real hardware and MiSTer.

-------------------------------------------------------------------------------
 5. KNOWN ISSUES
-------------------------------------------------------------------------------
 - A few story readings are interpretive. See script/TRANSLATION_NOTES.md in
   the source repository.
 - The game's existing English graphics (title, LIFE/ATTACK/SPEED, staff
   credits) are unchanged.

Bug reports: https://github.com/struktured-labs/trinea-dx/issues

-------------------------------------------------------------------------------
 6. CREDITS
-------------------------------------------------------------------------------
 struktured labs (struktured)
     Project lead, LLM-assisted translation (curated by playing through each
     character's story), ROM hacking, fonts, tools, testing
 eadmaster
     RetroSubs English subtitles for Trinea, the base for Sara's story
     only, and the character table files. Ryo's and Hornisse's stories
     and the menus were translated from scratch.
     https://github.com/eadmaster/RetroSubs
 4ph
     Character table help (the byte-to-Japanese-character mapping)
     https://www.romhacking.net/forum/index.php?topic=40638.0
 Yanoman / Japan Art Media (JAM)
     The original game

 Tools: asar, Floating IPS (Flips), Mesen, bsnes-mercury, Python.

-------------------------------------------------------------------------------
 7. LICENSE
-------------------------------------------------------------------------------
The translation (English text, fonts, tables) is licensed under Creative
Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0), because
Sara's story builds on eadmaster's RetroSubs English translation
(CC BY-NC-SA 4.0).
The patch code and build tools are MIT-licensed; see the source repository.
Distribute this patch under CC BY-NC-SA 4.0: free of charge, with credit,
and share-alike.

Do NOT distribute pre-patched ROMs. Trinea is (c) 1993 Yanoman / Japan Art
Media. This is an unofficial fan translation, not affiliated with the rights
holders.

-------------------------------------------------------------------------------
 8. CHANGELOG
-------------------------------------------------------------------------------
 v1.2.2 (2026-11-12)
   - Configuration menu: about 1px of extra space between lines
     (suggested by eadmaster, issue #18). Letters are the same as
     v1.2.1; the list is moved up 2px so it still fits the window.
   - Labels renamed for consistency (also eadmaster, issue #18):
     Turbo is now Game Speed (Normal / Turbo); Fast foes is now
     Enemy Speed (Normal / Fast); Shortcuts is now L/R Shortcuts;
     Hero Speed's default value is Normal instead of Off (Fast /
     Faster unchanged). Option cycles and saved settings are
     unchanged. Rumble and L/R Shortcuts still say Off / On.
 v1.2.1 (2026-11-10)
   - Fixed: a brief tap of L or R sometimes did nothing (the 3-frame
     L+R chord window dropped a press that came up before the shortcut
     committed). A quick L or R now always fires once. Held L/R still
     wait those 3 frames so a sloppy L+R does not fire L or R first.
     L+R timing is unchanged.
 v1.2.0 (2026-11-10)
   - Title menu is now LOAD GAME / NEW GAME / OPTIONS. Start on OPTIONS
     opens Configuration (Turbo, Fast foes, Hero Speed, Rumble,
     Shortcuts, plus a nested Sound Test). Settings still save in SRAM.
   - Field L+R+button DX option hotkeys are retired. L/R are per-hero
     move shortcuts when Shortcuts is On (the default). Off restores
     original shoulder input and spends no gold. Suggested in issue #16
     (eadmaster).
   - L+R fires the rotate special after about 0.5s and keeps the facing
     you had when you pressed them. Release either shoulder during that
     window to cancel.
   - Fixed: moving the title cursor did not reset the ~10s attract idle
     timer, so walking down to OPTIONS could start the demo.
 v1.1.3 (2026-11-01)
   - Fixed: Play Level Easy (hidden Configuration menu: press Select on
     CONTINUE/START at the title) was reversed. Easy now deals Normal
     damage and takes half damage (min 1). Hard still doubles monster
     damage, now capped at 255. Normal is unchanged (#13).
   - Fixed: hero speed (L+R+Y) now actually makes Ryo faster once the
     screen scrolls (#15).
   - The Select overlay now says Ryo's shadow clones need a fast spin
     ("Spin D-pad (fast) then Y").
 v1.1.2 (2026-10-31)
   - Fixed: the Select controls overlay text was shifted sideways and
     wrapped in stages that scroll BG3 with HDMA (e.g. Neo Edo). The
     overlay now holds BG3 horizontal scroll at 0 on every line (#12).
 v1.1.1 (2026-10-28)
   - Removed the L+R+Select dialogue-skip toggle (it was undocumented in
     the game). Start always skips dialogue, also on saves that had it
     off; L+R+Select now does nothing.
 v1.1 (2026-10-28)
   - Reduces some of the original game's slowdown; L+R+button option
     toggles, rumble, Select controls
     overlay (Hornisse blue, Sara green, Ryo pink; Hornisse A = Overhead,
     Y = Low sweep), Start skips dialogue, staff roll credits.
   - Fixed: final-boss freeze (rumble left X/Y 8-bit during NMI);
     0 freezes in 45 soak runs vs ~2 in 39 before.
   - Wizard spelled "Graph" consistently; opening line fix.
   - Less slowdown in busy scenes (game logic unchanged).
   - Fixed: Start pressed while the save list drew left it as
     "Chronicle 1" and "C". Start now skips from the next prompt.
   - Removed the L+R+Start overlay toggle (easy to hit by accident);
     L+R+Start is a plain Start and the Select overlay is always on.
 v1.0.1 (2026-10-13)
   - Fixed: dialogue text corrupted the stage collision map, so after
     talking you could get stuck in walls or walk through them (e.g. after
     a boss victory). Text now uses RAM the game never touches.
 v1.0 (2026-09-26)
   - First public release. Complete English translation.
===============================================================================
