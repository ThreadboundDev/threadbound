# Threadbound Demo Ending

The demo ending is an isolated presentation flow and is not part of the canonical full-game ending system.

## Player Flow

1. The Proto-Weaver encounter resolves normally.
2. On defeat, the boss detaches, retreats to the center floor, and plays its authored death animation while the camera focuses on it.
3. The camera returns to the player and the ending blossom appears at the right side of the boss arena. The boss does not drop thread knots during this presentation.
4. Interacting with the blossom offers **Continue to End Demo** or **Keep Exploring**.
5. Continuing opens the thank-you screen with feedback, credits, and main-menu options.

## Editing Content

Edit `Src/UI/PlaytestSupport/threadbound_playtest_support.tres` to change:

- the published playtest-report URL;
- the published bug-report URL;
- the QR texture;

Edit `Src/UI/DemoEnding/threadbound_demo_ending.tres` to change:

- thank-you wording;
- Chase's optional personal note;
- credit categories and entries.

The credit category and entry arrays are parallel: entries at the same index are displayed together.
When the personal note is non-empty, the ending screen displays it behind an optional **A Note from Chase** button.

## During the Demo

A new journey opens with a one-time testing welcome. It explains that **Playtest Support** remains available from both the pause menu and the main menu throughout the demo. Continuing an existing checkpoint does not display the welcome again.

The support section separates broad playtest feedback from focused bug reports:

- Playtest report: `https://tally.so/r/Bzo0z5`
- Bug report: `https://tally.so/r/81DrqP`

Both Tally forms use the Threadbound title artwork, a dark theme, and gold accents. Their wording and questions remain editable in Tally without changing the game.

## Debug Testing

In debug builds:

- Press `F3` to defeat the active Proto-Weaver through its normal health/death signal path.
- Press `F4` from any scene to open the ending screen immediately. Debug opening does not record demo completion.

Run the automated check with:

```text
godot --headless --path . --scene res://tools/demo_ending/verify_demo_ending.tscn
```
