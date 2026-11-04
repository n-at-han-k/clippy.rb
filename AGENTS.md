# clippy.rb

Clippy as a GTK4 desktop overlay in Ruby. Started from the `gnome-contacts-rb`
scaffolding (kettle-jem packaging, the Nix flake, the custom cops, the test
harness); all of that port's application code was removed first.

## Skills — use them

Two skills are installed in `.claude/skills/`. They are not optional reading.

- **ruby-gtk** — the house style for Ruby GTK4/Libadwaita: the declarative
  memoized-widget pattern, binding quirks, worked examples. Load it before
  writing or reviewing ANY Ruby GTK code, including single widgets. The
  bindings are quirky enough that code written from memory is unreliable.
- **ruby-gtk-testing** — run the app headlessly and drive its UI: assert
  widget state, capture screenshots. Use it before claiming any GTK change
  works. `ruby -c` and a successful `require` prove nothing about a UI.

## Setup

`direnv allow` (or `nix develop`) gets Ruby, GTK4, the introspection typelibs
and `wmctrl`. Then `ruby exe/clippy`.

## Verified binding facts

Checked against ruby-gnome 4.3.9 / GTK 4.22 in this repo. Do not "fix" code
back to the GTK3 forms.

| Thing | Reality |
|---|---|
| `Gtk::Window#set_keep_above` | **Does not exist in GTK4.** Removed, not deprecated. Always-on-top goes through `lib/clippy/always_on_top.rb`. |
| `Gtk::Window#begin_move_drag` | **Gone.** Use `window.surface.begin_move(device, button, x, y, time)`. |
| `Gtk::PopoverMenu.new` | Positional only. `Gtk::PopoverMenu.new(model: menu)` raises `ArgumentError`; `Gtk::PopoverMenu.new(menu)` works. |
| `Gdk::Display.default.class.name` | **nil** on Wayland — the class is anonymous. Use `.class.to_s`. |
| `Gtk::Revealer` CROSSFADE | Still requests the child's full size while hidden. Only the SLIDE transitions collapse to zero. |
| `Gtk::Window#realize` before `present` | Fails: no frame clock yet. The X11 window id is only available after mapping. |
| `Gdk::Texture.new(pixbuf)` | Works, and `Gtk::Picture#paintable=` swaps frames cheaply. |

## Testing

```sh
env -u DISPLAY -u WAYLAND_DISPLAY ruby test/drive_overlay.rb   # UI + screenshots
env -u DISPLAY -u WAYLAND_DISPLAY ruby -Ilib \
  -e 'Dir["test/test_*.rb"].each { |f| require File.expand_path(f) }'
```

Assert geometry with `Gtk::Widget#measure`, never `allocated_width`/`height`:
an allocation only catches up when the frame clock ticks, and a headless frame
clock does not tick reliably — allocation-based checks failed about one run in
three. Likewise, anything about a widget's state *before* the window is mapped
belongs in a unit test, not a driver step: the offscreen backend synthesises
crossing events, so the close button may legitimately be revealed by the time
the first step runs.

Read the screenshots in `tmp/shots/`, do not just trust the check count. Three
real bugs in this code were found by looking at them and not by asserting: a
46px invisible band above Clippy's head, a squashed sprite, and a close button
that never rendered.

## Style

`.rubocop.yml` plus the custom cops in `cops/` are enforced: no `return`, no
modifier `if`, no conditional assignment, `tap` where it applies, and fixed
multi-line argument/hash layout. Run `rubocop` before committing.

## Honesty about gaps

`.claude/skills/accountability-ensurance` applies. The "Known gaps" section of
the README states what is missing as missing. Do not reword those into
"deliberate scope decisions" — nobody decided Clippy should be silent, the
audio playback simply has not been written.
