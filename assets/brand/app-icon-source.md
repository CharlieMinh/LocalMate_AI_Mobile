# App icon source

Approved direction: robot in the existing location pin, golden orbit arrow, no wordmark. Source: `logo.jpg` in this directory, left unchanged.

Artwork mode: **built-in image_gen edit**, transparent background, 27 October 2026. No external photograph or new brand reference was used. This is an AI-assisted extraction/adaptation of the existing symbol, not a claim of byte-identical cropping.

Final transparent artwork: `app-icon-mark.png`. Technical Android density/adaptive/monochrome and opaque Play Store exports: `tool/export_android_icons.ps1`.

Prompt:

```text
Use case: background-extraction / identity-preserve. Asset type: source artwork for LocalMate AI Android launcher icon. Image 1 is the edit target, the existing approved brand logo. Extract ONLY the complete symbol above the words: the navy-blue map pin containing the friendly white robot face and antenna, golden orbit arrow wrapping around the pin, golden city skyline and white curved road. Remove the entire 'LocalMate AI' wordmark beneath it, and remove the external white background to true transparent alpha. Preserve the original identity, face expression, two eyes, smiling mouth, antenna, pin silhouette, orbit direction and arrow tip, skyline and road. Keep original navy/blue, white and golden-yellow colors, flat crisp vector-like edges. White INSIDE the robot face and road must remain opaque white; only outside the mark is transparent. Do not add objects, letters, a tile, shadows, gradients, glow, or a new design. Place the complete extracted mark centered on a square high-resolution transparent canvas with about 10% clear padding on each edge; no part including arrow tip or pin point can be clipped. Output a single clean transparent PNG artwork, not a mockup or presentation. Later packaging will generate exact Android sizes and adaptive-icon safe margins.
```
