# Threadbound Demo Ending

The demo ending is an isolated presentation flow and is not part of the canonical full-game ending system.

## Player Flow

1. The Proto-Weaver encounter resolves normally.
2. After a short delay, the ending blossom appears at the right side of the boss arena.
3. Interacting with it offers **Continue to End Demo** or **Keep Exploring**.
4. Continuing opens the thank-you screen with feedback, credits, and main-menu options.

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

In debug builds, press `F4` from any scene to open the ending screen immediately. Debug opening does not record demo completion.

Run the automated check with:

```text
godot --headless --path . --scene res://tools/demo_ending/verify_demo_ending.tscn
```
