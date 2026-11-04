# Clippy assets

`map.png` and `agent.json` are the Clippy agent from
[smore-inc/clippy.js](https://github.com/smore-inc/clippy.js)
(`agents/Clippy/map.png` and `agents/Clippy/agent.js`), which in turn carries
the sprite sheet extracted from the Microsoft Office Assistant.

- `map.png` — 3348×3162 sprite sheet, a 27×34 grid of 124×93 frames. The
  original magenta key colour (255, 0, 255) is already converted to alpha, so
  frames composite over a transparent window with no colour-keying at runtime.
- `agent.json` — the animation table, unwrapped from the `clippy.ready('Clippy', …)`
  JSONP call in the upstream `agent.js` into plain JSON. Content is byte-identical
  to upstream's, only the JS wrapper is gone.

43 animations, 1233 frames. Each frame has a `duration` in milliseconds, an
`images` array of `[x, y]` offsets into the sheet, and optionally a `sound` id,
an `exitBranch` and a `branching` weight table. See `lib/clippy/agent.rb`.

Upstream ships no licence file. The sprites are Microsoft artwork and are
vendored here for interoperability with the original agent format; they are not
covered by this project's GPL-2.0-or-later licence. Replace `data/clippy/` with
your own agent if you intend to redistribute.

The 15 voice samples (`sounds-mp3.js` / `sounds-ogg.js` upstream) are NOT
vendored — nothing plays audio yet. The `sound` ids are preserved in
`agent.json` so a future player can wire them up.
