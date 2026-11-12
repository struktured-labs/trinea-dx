# Trinea DX: moves and in-game toggles

These moves were checked in play and in the game code.

## Resources
- **X special counter** ($7E:10B8): only the X button uses it. It starts at 1 and goes up to 5. Pickups and the shop each add 1 ("X Special uses +1!!", or "Adds 1 use of the X special." in the shop).
- **Gold:** each rotate move costs 10% of your current gold, with a minimum of 10G. You can't use one with less than 10G (C0:836C).
- **A+B moves are free.**

Spin check (C0:8707): the last four D-pad changes before the button, sampled every 4 frames, must cover all four directions, and each must be held for fewer than N samples: N = 6 for Hornisse and Sara (about 24 frames per direction), N = 2 for Ryo (about 8 frames). So Ryo needs a faster spin than the others, not a slower one; a headless test with 4-way spins succeeded 20/20 at 6-7 frames per direction and 0/20 at 9 or more.

Button tables: C0:894B (Hornisse), C0:88FE (Sara), C0:8998 (Ryo). Each maps a button or combo to an action, and the first match wins. Move names come from watching each move in Mesen.

## Hornisse
| Input | Move | Cost |
|---|---|---|
| B | stab | free |
| A | overhead slash ("Overhead" in the Select overlay) | free |
| Y | low sweep ("Low sweep" in the Select overlay) | free |
| B+Y | no move of its own: his table has no B+Y entry, so it is the B stab | free |
| mash B (4 quick taps, about 5-10 taps/s) | sword frenzy | free |
| A+B | morning star | free |
| rotate the D-pad, then A | lightning ("Electric Buffalo") | 10% gold (min 10G) |
| X | shock wave (he raises his sword, the screen pulses blue with a dark ring at his feet, then every enemy on screen explodes) | 1 X-special use |

## Sara
| Input | Move | Cost |
|---|---|---|
| rotate the D-pad, then B | Dragon Fire | 10% gold (min 10G) |
| B | fire shot (sparks fly forward) | free |
| A | spark shot (small magic bolt) | free |
| Y | wing spin (she turns a full circle with her wings spread; close range, no projectile) | free |
| B+Y | star fall (Sara glows gold, then a huge star crashes down) | free |
| A+B | homing flame (sparks steer into the nearest enemy; looks like B with no enemy on screen). A and B must go down on the same frame: the first button pressed locks in the move (A first = A, B first = B) | free |
| X | giant star (the screen pulses red and a huge purple star-field star grows over the whole screen, hitting every enemy) | 1 X-special use |

## Ryo
| Input | Move | Cost |
|---|---|---|
| rotate the D-pad fast (each direction held about 8 frames or less, a full circle in about half a second), then Y | shadow clones | 10% gold (min 10G) |
| B | sickle (close range) | free |
| A | chain sickle (thrown on a chain) | free |
| Y | throwing blade | free |
| B+Y | wall of fire (a column of flames in front of him) | free |
| A+B | bombs | free |
| X | petal storm (the screen turns magenta and three-lobed petals swirl across it, then every enemy on screen explodes) | 1 X-special use |

## L/R move shortcuts (issue #16)
When **L/R Shortcuts** is On in Configuration (the default), shoulder buttons synthesize the matching special for the current hero (P1). L and R are cleared from the game pad so they are dedicated to shortcuts. Turn L/R Shortcuts Off to use the original shoulder input: no L/R specials fire and rotate-move gold is not spent from a shortcut.

| Hero | L | R | L+R |
|---|---|---|---|
| Hornisse | mash B (Sword frenzy) | A+B (Morning star) | hold L+R ~0.5s (Lightning) |
| Sara | B+Y (Star fall) | A+B (Homing flame) | hold L+R ~0.5s (Dragon Fire) |
| Ryo | B+Y (Wall of fire) | A+B (Bombs) | hold L+R ~0.5s (Shadow clones) |

Hold L/R (or both) in the field or a stage. A brief tap of L or R still fires its shortcut (the injected combo is held long enough for the game to see it after the shoulder comes up). L+R waits about half a second (30 joy/NMI frames, not shortened by Turbo) then fires the rotate special directly: no synthetic D-pad 360. Releasing either shoulder before that window cancels; the leftover shoulder does not fire L or R. The special uses the facing from the moment L+R went down (Sara Dragon Fire no longer turns to north because a fake spin ended on Up). Manual rotate-then-button input is unchanged.

## DX options (Configuration menu)
Game Speed (Normal / Turbo), Enemy Speed (Normal / Fast), Hero Speed (Normal / Fast / Faster), Rumble, and L/R Shortcuts are toggled in the **Configuration** menu (title OPTIONS, or Select on the title). The old field L+R+button hotkeys are retired. Settings stay in battery SRAM ($30:6300 opts, $30:6304 Shortcuts); defaults are Normal / off, except rumble (on until turned off) and L/R Shortcuts (on until turned off). Old saves and blank SRAM leave L/R Shortcuts on.

## Select: controls help
Press **Select** in the field or a stage (anywhere Start would pause) to freeze the game and show a full-screen page: an SNES pad with what each button does (including the L/R shortcuts above), plus the current character's moves from this file. Tip line: `{L}/{R}: shortcuts` / `{L+R}: special`. **Select or Start** closes it and the screen comes back exactly as it was (the music keeps playing). It never opens in menus, shops, dialogue, cutscenes or the attract demo. It is always available (no off switch). In the original game Select does nothing in play, so nothing is taken away. Screenshots: `docs/screenshots/help_overlay_*.png`.

## Start skips dialogue
While a message is printing or waiting for A, press **Start** to skip the rest of the current scene's text (a press while text is still printing takes effect at the next prompt, so menus such as the save list always draw in full). The script still runs every non-text command (story flags, map moves, items, LIFE, character branches, battles), so nothing is missed; only the text is hidden and [wait] prompts are passed. Choice prompts and menus still appear and wait for you. Start = pause in gameplay is unchanged (skip only acts while a script is running). It is always available (no toggle since v1.1.1).

## Rumble: Count Vampierre's zap
In the NEA 1426 revival scene, when the Count vaporizes Gostelo, a crackly strong pulse plays for exactly as long as the zap animation (script op 39 at $E2:1DD4). It does not play if you skipped the scene with Start.

## Tips
- The contraption boss is easy if you attack it from the side.
