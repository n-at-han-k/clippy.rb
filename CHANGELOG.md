# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This repository began as a clone of `gnome-contacts-rb`, kept for its packaging,
Nix flake, custom cops and test harness. All of that project's application code
was removed before this one was written, so the git history before the first
Clippy commit is that project's and not this one's.

## [Unreleased]

### Added

- Clippy as a frameless, transparent GTK4 overlay window, with the original
  sprite sheet and all 43 animations from the Microsoft Agent format
  (`data/clippy/`, vendored from clippy.js — see `data/clippy/PROVENANCE.md`).
- Per-frame animation timing, weighted `branching`, and `exitBranch` handling,
  so idle animations loop and leave the way the originals did.
- Speech balloon with a Cairo-drawn tail and a reading-length dwell timer.
- Always-on-top via the EWMH `_NET_WM_STATE_ABOVE` client message on X11 and
  Xwayland, with an honest startup message when the session cannot support it.
- Dragging via `Gdk::Toplevel#begin_move`, a right-click animation menu, and a
  hover-reveal close button.
- `exe/clippy` with `--animation`, `--scale`, `--list`, `--wayland`,
  `--version`.
- Headless UI driver (`test/drive_overlay.rb`, 34 checks plus screenshots) and
  35 unit tests covering the agent loader, frame succession, the overlay's
  construction, and display-backend detection.
- `gem_kit-release` for release tooling, which from 0.4.0 reads this gem's
  dotted name correctly: `clippy.rb` resolves to `lib/clippy/version.rb`.
