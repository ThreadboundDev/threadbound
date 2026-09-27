# Player Pogo Attack Visual

## 2026-08-26 — Dedicated Downward Strike

- Added a dedicated 11-frame pogo sheet with a short airborne wind-up, strong
  downward weapon commitment, long ivory vertical smear, impact accents, and a
  compressed follow-through.
- Preserved the established stitched mask, black clothing, dark contour,
  bronze-gold weaving shuttle, 416 px cells, 40 FPS playback, and transparent
  runtime presentation.
- Rewired only the existing `Pogo_Attack` SpriteFrames entry. Pogo damage,
  strike frames, AP behavior, attack direction, rebound speed, gravity grace,
  and recovery were not changed.
- Added a repeatable normalization script and targeted verification scene.
- Extended the broad player-animation verifier to reject future accidental
  reuse of the air-double-attack atlas for pogo.

The generated alpha source is retained beside the normalized runtime sheet for
future paint cleanup or timing revisions.
