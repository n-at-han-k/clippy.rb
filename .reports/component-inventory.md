# gnome-contacts-rb — upstream component inventory

Survey of GNOME Contacts (`origin/main`, Vala + blueprint) against the Ruby
port on `ruby`. Produced with the `component-identification` skill: the
`.blp` files were read first (they are the component map), then the Vala that
backs them, then the port's `lib/*.rb`.

## Totals

Scan of upstream `src/` + `data/` versus the port's `lib/`, filtered to the
files actually in each tree (the shared scratchpad was polluted by sibling
workers; rows were re-joined against `git ls-tree origin/main`):

| | upstream | port |
|---|---:|---:|
| widget rows / distinct types | 269 / 49 | 160 / 44 |
| CSS classes (rows / distinct) | 55 / 32 | 30 / 14 |
| signals (rows / distinct) | 53 / 28 | 42 / 19 |
| actions (rows / distinct) | 44 / 33 | 33 / 14 |
| controllers | 6 / 3 | 1 / 1 |

Upstream source: 9 825 lines of Vala across 71 files, 1 021 lines of blueprint
across 13 files, 1 C widget (`cc-crop-area.c`), 1 GSettings schema, 1 GResource
manifest, 79 `po/` locales. Port: 5 917 lines of Ruby across 29 files.

The port is close to full parity on structure. What is missing is almost
entirely **chrome**: the translations, the packaging data, and a handful of
action/accelerator mismatches at the edges.

> **Refreshed 2026-11-02.** Commit `744f3b2b` extracted the avatar, the type
> combo row, the birthday editor and the accounts list into their own files,
> and `lib/main.rb` has since grown the CSS provider, the `Adw.Breakpoint`, the
> loading spinner and the alert dialogs. The `exists` column and the gap
> section below reflect the tree as of that refresh; the totals table above is
> from the original survey and is now low on the port side (`lib/` is 6 577
> lines across 31 files).

## Component map

Order: the application, the first-run window, the main window and its pages,
then the dialogs, then the non-widget layers.

| # | upstream file(s) | port file | kind | exists |
|--:|---|---|---|:--:|
| 1 | `src/main.vala`, `src/contacts-app.vala` | `lib/main.rb` | application | yes |
| 2 | `src/contacts-setup-window.vala` + `data/ui/contacts-setup-window.blp` | `lib/setup_window.rb` | window | yes |
| 3 | `src/contacts-accounts-list.vala` | `lib/accounts_list.rb` | widget (prefs group) | yes |
| 4 | `src/contacts-main-window.vala` + `data/ui/contacts-main-window.blp` | `lib/main.rb` | window | yes |
| 5 | `menu primary_menu_popover` (main-window.blp) | `lib/main.rb` | menu | yes |
| 6 | `menu contact_hamburger_menu_popover` (main-window.blp) | `lib/main.rb` | menu | yes |
| 7 | `ShortcutController` (main-window.blp) | `lib/main.rb` | keyboard shortcuts | partial |
| 8 | `Adw.Breakpoint` (main-window.blp) | `lib/main.rb` | adaptive breakpoint | yes |
| 9 | `Adw.Spinner` loading page (main-window.blp) | `lib/contact_list.rb` | loading state | yes |
| 10 | `src/contacts-contact-list.vala` | `lib/contact_list.rb` | widget (ListView) | yes |
| 11 | `src/contacts-contact-selection-model.vala` | `lib/contact_store.rb` | model | yes |
| 12 | `src/contacts-contact-pane.vala` + `data/ui/contacts-contact-pane.blp` | `lib/contact_pane.rb` | page (stack) | yes |
| 13 | `src/contacts-contact-sheet.vala` | `lib/contact_sheet.rb` | widget | yes |
| 14 | `src/contacts-contact-sheet-row.vala` + `data/ui/contacts-contact-sheet-row.blp` | `lib/contact_sheet_row.rb` | row | yes |
| 15 | `src/contacts-avatar.vala` | `lib/avatar.rb` | widget | yes |
| 16 | `src/contacts-contact-editor.vala` | `lib/contact_editor.rb` | page (form) | yes |
| 17 | `data/ui/contacts-birthday-editor.blp` + `BirthdayEditor` in `contacts-contact-editor.vala` | `lib/birthday_editor.rb` | dialog | yes |
| 18 | `src/contacts-type-combo.vala` | `lib/type_combo_row.rb` | row (ComboRow) | yes |
| 19 | `src/contacts-editable-avatar.vala` + `data/ui/contacts-editable-avatar.blp` | `lib/editable_avatar.rb` | widget | yes |
| 20 | `src/contacts-avatar-selector.vala` + `data/ui/contacts-avatar-selector.blp` | `lib/avatar_selector.rb` | dialog | partial |
| 21 | `src/contacts-crop-dialog.vala` + `data/ui/contacts-crop-dialog.blp` + `src/cc-crop-area.c/.h` | `lib/crop_dialog.rb` | dialog | yes |
| 22 | `src/contacts-qr-code-dialog.vala` + `data/ui/contacts-qr-code-dialog.blp` | `lib/qr_code_dialog.rb` | dialog | yes |
| 23 | `src/contacts-link-suggestion-grid.vala` + `data/ui/contacts-link-suggestion-grid.blp` | `lib/link_suggestion_grid.rb` | widget | yes |
| 24 | `src/contacts-import-dialog.vala` + `data/ui/contacts-import-dialog.blp` | `lib/import_dialog.rb` | dialog | yes |
| 25 | `src/contacts-preferences-window.vala` + `data/ui/contacts-preferences-window.blp` | `lib/preferences_dialog.rb` | dialog | partial |
| 26 | `data/ui/contacts-shortcuts-dialog.blp` | `lib/shortcuts_dialog.rb` | dialog | yes |
| 27 | `Adw.AboutDialog` in `contacts-app.vala` | `lib/main.rb` | dialog | yes |
| 28 | `Adw.AlertDialog`s in `contacts-app.vala` / `contacts-main-window.vala` / `contacts-avatar-selector.vala` | `lib/main.rb` | error states | yes |
| 29 | `src/contacts-operation*.vala`, `contacts-{delete,link,unlink,import}-operation.vala`, `contacts-operation-list.vala` | `lib/operations.rb` | undo stack + toasts | partial |
| 30 | `src/contacts-shell-search-provider.vala` + `data/org.gnome.Contacts.search-provider.ini.in` + `.service.in` | `lib/shell_search_provider.rb` | D-Bus service | yes |
| 31 | `src/contacts-settings.vala` + `src/org.gnome.Contacts.gschema.xml` | `lib/settings.rb` | settings | yes (JSON) |
| 32 | `src/core/contacts-contact.vala` + the 14 `*-chunk.vala` files | `lib/contact.rb` | model | yes |
| 33 | `src/core/contacts-type-set.vala`, `-type-descriptor.vala`, `-vcard-type-mapping.vala` | `lib/type_set.rb` | model | yes |
| 34 | `src/contacts-{chunk,chunk-empty,chunk-property,query,manual,persona}-filter.vala`, `*-sorter.vala`, `contacts-store.vala` | `lib/contact_store.rb` | model | yes |
| 35 | `src/io/*` | `lib/vcard.rb`, `lib/vcard_backend.rb`, `lib/json_backend.rb`, `lib/backend.rb` | io | yes |
| 36 | `src/contacts-im-service.vala` | `lib/im_service.rb` | model | yes |
| 37 | `src/contacts-ui-state.vala` | `lib/main.rb` (state constants) | enum | yes |
| 38 | `src/contacts-utils.vala` | folded into callers | helpers | partial |
| 39 | `src/contacts-esd-setup.vala` | — | EDS bootstrap | n/a |
| 40 | `data/style.css` | — | stylesheet | partial |
| 41 | `po/` (79 locales, `POTFILES.in`) | — | translations | **no** |
| 42 | `data/contacts.gresource.xml`, `data/icons/*`, `*.desktop.in.in`, `*.metainfo.xml.in.in` | — | packaging/resources | **no** |

## Per-component detail for the gaps

Rewritten at the 2026-11-02 refresh. The four units the first survey listed as
missing (`lib/avatar.rb`, `lib/type_combo_row.rb`, `lib/birthday_editor.rb`,
`lib/accounts_list.rb`) now exist, as do the breakpoint, the loading spinner,
the CSS provider and the alert dialogs. What follows is what is still open.

### Blocker — the gem entry point runs the scaffold, not the port

`exe/gnome-contacts` is `GnomeContacts::Application.new.build.run`, and
`lib/gnome_contacts.rb` requires `gnome_contacts/application`, which is still
the fork scaffold: one `Adw.StatusPage` reading "The Ruby port has not been
written yet." The real application is `lib/main.rb`, reachable only by running
that file directly. Installing the gem and running `gnome-contacts` shows the
placeholder. Either `exe/gnome-contacts` must point at `lib/main.rb`'s class or
`lib/gnome_contacts/application.rb` must become a thin shim over it.

### Actions and accelerators

| Gap | Upstream | Port |
|---|---|---|
| `win.cancel-operation` | `{ "cancel-operation", cancel_operation_action, "s" }`; the link toast offers `_Cancel` against it (`contacts-main-window.vala:558`) | absent from `WINDOW_ACTIONS` |
| `win.undo-operation` parameter | takes an `s` (the operation id) | takes no parameter (`lib/main.rb:54`) |
| `win.sort-on` targets | `"firstname"` / `"surname"` (main-window.blp:13, 18) | `win.sort-on::first-name` / `::surname` (`lib/main.rb:369-370`) — the surname arm matches, the first-name arm does not |
| `<Control>Delete` | `Shortcut` → `action(win.delete-marked-contacts)` (main-window.blp) | `'delete-marked-contacts' => []`, no accelerator |

### Still-absent widgets

- **The GOA button in Preferences.** `contacts-preferences-window.vala:26-52`: an `Adw.ButtonContent` labelled "_Online Accounts", tooltip "Open the Online Accounts panel in Settings", on a `Gtk.Button` with the `pill` class, firing `launch-panel` on `org.gnome.Settings` over D-Bus. No counterpart in `lib/preferences_dialog.rb`.
- **The camera button in the avatar selector.** `camera_button` "_Take a Picture…" and its `Gtk.ActionBar` host. Absent by design — no XDG portal binding in ruby-gnome — and documented as such in `lib/avatar_selector.rb`.
- **The editor "show more" revealers.** Upstream puts an `Adw.ButtonRow` behind two nested `Gtk.Revealer`s on each multi-value group; `lib/contact_editor.rb` always shows every row.
- **Sheet persona-store headings.** Upstream inserts a `Gtk.Label` when consecutive chunks come from different personas; the port has no equivalent.
- **List-row gestures.** Upstream's rows carry a `Gtk.GestureClick` (secondary button) and a `Gtk.GestureLongPress` to enter selection mode; `lib/contact_list.rb` attaches neither.

### Chrome

- **`data/style.css` — partial.** `lib/main.rb:298` installs a `Gtk::CssProvider`, but by its own comment only the rules whose classes the port actually applies were carried over. Upstream's per-property editor selectors (`contacts-editor-property`, `contacts-editor-address`, `contacts-persona-editor`, `contacts-property-icon`, `contacts-cutout-button`) have no port counterpart to style.
- **`po/` — absent.** No `po/` directory, no gettext calls, every string an English literal. Upstream ships 78 locales plus `POTFILES.in` over 13 `.blp` and 30 `.vala` files. This is the single largest remaining parity gap by volume.
- **Packaging data — absent.** No `data/`: no `.desktop`, no metainfo, no app icons, no GResource. The port needs no GResource, but the desktop file and icon are user-facing.
- **Tests — absent.** `spec/` holds only `spec_helper.rb` and a README; no component has a spec.

## Repeaters and conditionals

- **Contact rows** — `contact_list.rb` `list_factory`, one per contact in the selection model; each row carries a `Gtk.CheckButton.selection-mode` revealed only in selection mode, plus upstream's `Gtk.GestureClick` (secondary) and `Gtk.GestureLongPress`, which the port does not attach.
- **Section headers** — upstream's `header_factory` builds one `Gtk.Label.heading.dim-label` per initial letter; the port reproduces it in `contact_list.rb:228`.
- **Editor field rows** — `contact_editor.rb` keeps one blank `Adw.EntryRow` at the end of every multi-value group; typing appends another. Upstream does the same, plus an `Adw.ButtonRow` "show more" behind two nested `Gtk.Revealer`s that the port does not have.
- **Sheet field groups** — upstream adds a group only for chunks the contact has, and inserts a `Gtk.Label` persona-store heading when consecutive chunks come from different personas. The port always renders every group with a placeholder row, and has no persona-store heading.
- **Import dialog** — one `Adw.PreferencesGroup` per file, one `Adw.ActionRow` per parsed contact, one `Gtk.Label.error` per unreadable file; an `Adw.Spinner` while parsing.
- **Address-book rows** — one per EDS source upstream, one per configured backend in the port.
