# Threadbound menu concepts

Open [the review gallery](index.html) in a browser. The top bar switches
screens. The accent picker previews Chamber, Blue, Red, and Yellow.

The concepts reuse Almendra, the Chamber artwork, the actual map, and existing
item art. Dark panels and plain borders replace decorative frames. Accent
color shows focus, selected tabs, and relevant values.

| Screen | What the concept preserves |
| --- | --- |
| Pause | Resume, Settings, Playtest Support, and Quit in one column over the scene |
| Settings | Graphics, Audio, Gameplay, and Controls tabs with the existing settings grouped as rows |
| Inventory | Standing doll with Weapon and Gloves on the left, Head / Chest and Boots on the right, and Pattern above. The bag, Thread Identity, stats, four categories, item details, and Equip keep their roles |
| Map, Lore, Controls | Chamber map and player marker, lore list and reading pane, device choice and rebinding |
| Blossom and Weave | Reflect, Weave, Listen, and Rise. Meditation keeps six stats, current and next values, knot costs, and the exit |
| Follower | Talk, Buy, and Leave. The shop retains the item list, prices, wallet, and details |
| Hot Swap | Monarch, Sage, and Hermit in the existing directional arrangement, with the active choice highlighted |
| Support and Demo Ending | Report and bug entry points, feedback QR, note, credits, and return to title |

Sample selections, settings, purchases, and upgrades work locally in the
gallery. The artwork and sample values are for review. The game keeps its
existing menus and behavior until a visual direction is chosen.

## Equipment icon standard for review

Use a **128 × 128 px transparent RGBA PNG** as the delivery canvas for each
equipment icon. Keep the visible silhouette inside a centered **104 × 104 px**
area. Preserve its proportions, use the same camera and soft light for a set,
and keep borders, rarity indicators, and focus rings in the interface. Review
each item at **64 × 64 px**, the artwork size in the desktop concept. Use an
**80 × 80 px** button for each equipped slot. A tall weapon can angle across
the safe area when that makes its silhouette easier to read.

The seven normalized samples and the Base and Blue portrait captures are in
`LocalOnly/MainMenuReview` on the development checkout. The gallery has
tracked fallback art for checkouts without those review exports. The sample
slot icons update with every gear choice. Its portrait has captures for the
full Base and full Blue outfits. The in-game inventory already has a live
preview that can show mixed gear.
