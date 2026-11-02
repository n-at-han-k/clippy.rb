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
entirely **chrome**: the stylesheet, the translations, the adaptive breakpoint,
and four dialogs/states that upstream shows at the edges.

## Component map

Order: the application, the first-run window, the main window and its pages,
then the dialogs, then the non-widget layers.

| # | upstream file(s) | port file | kind | exists |
|--:|---|---|---|:--:|
| 1 | `src/main.vala`, `src/contacts-app.vala` | `lib/main.rb` | application | yes |
| 2 | `src/contacts-setup-window.vala` + `data/ui/contacts-setup-window.blp` | `lib/setup_window.rb` | window | yes |
| 3 | `src/contacts-accounts-list.vala` | `lib/accounts_list.rb` | widget (prefs group) | **no** (inlined) |
| 4 | `src/contacts-main-window.vala` + `data/ui/contacts-main-window.blp` | `lib/main.rb` | window | yes |
| 5 | `menu primary_menu_popover` (main-window.blp) | `lib/main.rb` | menu | yes |
| 6 | `menu contact_hamburger_menu_popover` (main-window.blp) | `lib/main.rb` | menu | yes |
| 7 | `ShortcutController` (main-window.blp) | `lib/main.rb` | keyboard shortcuts | partial |
| 8 | `Adw.Breakpoint` (main-window.blp) | `lib/main.rb` | adaptive breakpoint | **no** |
| 9 | `Adw.Spinner` loading page (main-window.blp) | `lib/contact_list.rb` | loading state | **no** |
| 10 | `src/contacts-contact-list.vala` | `lib/contact_list.rb` | widget (ListView) | yes |
| 11 | `src/contacts-contact-selection-model.vala` | `lib/contact_store.rb` | model | yes |
| 12 | `src/contacts-contact-pane.vala` + `data/ui/contacts-contact-pane.blp` | `lib/contact_pane.rb` | page (stack) | yes |
| 13 | `src/contacts-contact-sheet.vala` | `lib/contact_sheet.rb` | widget | yes |
| 14 | `src/contacts-contact-sheet-row.vala` + `data/ui/contacts-contact-sheet-row.blp` | `lib/contact_sheet_row.rb` | row | yes |
| 15 | `src/contacts-avatar.vala` | `lib/avatar.rb` | widget | **no** (inlined) |
| 16 | `src/contacts-contact-editor.vala` | `lib/contact_editor.rb` | page (form) | yes |
| 17 | `data/ui/contacts-birthday-editor.blp` + `BirthdayEditor` in `contacts-contact-editor.vala` | `lib/birthday_editor.rb` | dialog | **no** |
| 18 | `src/contacts-type-combo.vala` | `lib/type_combo_row.rb` | row (ComboRow) | **no** (inlined) |
| 19 | `src/contacts-editable-avatar.vala` + `data/ui/contacts-editable-avatar.blp` | `lib/editable_avatar.rb` | widget | yes |
| 20 | `src/contacts-avatar-selector.vala` + `data/ui/contacts-avatar-selector.blp` | `lib/avatar_selector.rb` | dialog | partial |
| 21 | `src/contacts-crop-dialog.vala` + `data/ui/contacts-crop-dialog.blp` + `src/cc-crop-area.c/.h` | `lib/crop_dialog.rb` | dialog | yes |
| 22 | `src/contacts-qr-code-dialog.vala` + `data/ui/contacts-qr-code-dialog.blp` | `lib/qr_code_dialog.rb` | dialog | yes |
| 23 | `src/contacts-link-suggestion-grid.vala` + `data/ui/contacts-link-suggestion-grid.blp` | `lib/link_suggestion_grid.rb` | widget | yes |
| 24 | `src/contacts-import-dialog.vala` + `data/ui/contacts-import-dialog.blp` | `lib/import_dialog.rb` | dialog | yes |
| 25 | `src/contacts-preferences-window.vala` + `data/ui/contacts-preferences-window.blp` | `lib/preferences_dialog.rb` | dialog | partial |
| 26 | `data/ui/contacts-shortcuts-dialog.blp` | `lib/shortcuts_dialog.rb` | dialog | yes |
| 27 | `Adw.AboutDialog` in `contacts-app.vala` | `lib/main.rb` | dialog | yes |
| 28 | `Adw.AlertDialog`s in `contacts-app.vala` / `contacts-main-window.vala` / `contacts-avatar-selector.vala` | `lib/main.rb` | error states | **no** |
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
| 40 | `data/style.css` | — | stylesheet | **no** |
| 41 | `po/` (79 locales, `POTFILES.in`) | — | translations | **no** |
| 42 | `data/contacts.gresource.xml`, `data/icons/*`, `*.desktop.in.in`, `*.metainfo.xml.in.in` | — | packaging/resources | **no** |

## Per-component detail for the gaps

### `lib/accounts_list.rb` — the address-book list (missing as a unit)

Upstream `AccountsList : Adw.PreferencesGroup` with a private
`AddressbookRow : Adw.ActionRow`:

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.PreferencesGroup` | 1 | — | `notify::selected-store` | title/description set by its two callers |
| `Adw.ActionRow` | repeater | — | `activated` | one per EDS address book |
| `Gtk.Image` (provider icon) | 1/row | — | — | GOA account icon, else the app icon, `icon-size: large` |
| `Gtk.Image` (`object-select-symbolic`) | 1/row | — | — | bound to `selected`, is the activatable widget |

The port builds an equivalent group twice — `setup_window.rb:108`
(`address_book_list`) and `preferences_dialog.rb:66` (`address_books_group`) —
so the component exists on screen in both places but has no shared file. Both
sides are the join target for one `lib/accounts_list.rb`.

### `lib/avatar.rb` — the avatar (missing as a unit)

Upstream `Contacts.Avatar : Adw.Bin` wrapping one `Adw.Avatar`, which
re-renders on `notify::individual`. The port instantiates
`Adwaita::Avatar.new(AVATAR_SIZE, nil, true)` inline at
`contact_list.rb:210` and inside `contact_sheet.rb`, with no shared file.

### `lib/birthday_editor.rb` — the Set Birthday dialog (missing)

`data/ui/contacts-birthday-editor.blp`, an `Adw.Dialog` (`content-width: 360`):

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ToolbarView` + `Adw.HeaderBar` | 1 | — | — | no title buttons |
| `Gtk.Button` Cancel | 1 | — | `action-name: window.close` | |
| `Gtk.Button` `ok_button` "_Set" | 1 | `suggested-action` | `clicked => on_set_button_clicked` | |
| `Adw.PreferencesPage` / `Adw.PreferencesGroup` | 1 / 2 | — | — | fields group + remove group |
| `Adw.SpinRow` `day_spin` | 1 | — | — | adjustment 1–31, numeric |
| `Adw.ComboRow` `month_combo` | 1 | — | — | model is a `Gtk.StringList` of 12 month names |
| `Adw.SpinRow` `year_spin` | 1 | — | — | adjustment 1800–3000 |
| `Adw.ButtonRow` "Remove Birthday" | 1 | `destructive-action` | `activated => on_remove_activated` | |

The port replaces all of this with one free-text `Adw.EntryRow` —
`contact_editor.rb:134`, "Birthday (YYYY-MM-DD)". The birthday row on the
editor (`Adw.ActionRow` + `birthday-symbolic` prefix + `go-next-symbolic`
suffix with the `edit-icon` class) is therefore also absent.

### `lib/type_combo_row.rb` — the type dropdown (missing as a unit)

Upstream `TypeComboRow : Adw.ComboRow` whose model *is* a `TypeSet` and whose
expression is a `Gtk.PropertyExpression` on `display-name`, plus
`set_selected_from_vcard_type` / `set_selected_from_parameters`. The port
builds a `Gtk::DropDown`-style selector inline in `contact_editor.rb:229`
with an `Adwaita::AlertDialog` ("Custom Type") behind its "Other…" entry,
which upstream reaches the same way. Needs extracting to its own file.

### Missing states and chrome

- **`Adw.Breakpoint` `max-width: 560sp`** setting `content_box.collapsed: true`. Without it the split view never folds on a phone-width window.
- **The loading page.** `list_pane_stack` has two pages upstream: an `Adw.Spinner` with `dim-label`, and the list. The port's `contact_list.rb` stack has only `list`, `empty` and `no-results`, so the first second of startup shows an empty address book rather than a spinner.
- **Three `Adw.AlertDialog`s.** "Contact not found" / "No contact with id %s found" (`contacts-app.vala:103`), "Primary address book not found" with a "Go To _Preferences" suggested response (`contacts-app.vala:218`), "Discard changes?" guarding navigation away from an edit (`contacts-main-window.vala:453`), and "Failed to set avatar." (`contacts-avatar-selector.vala:247`). None exist in `lib/`; the port's only `AlertDialog` is the Custom Type prompt.
- **`win.cancel-operation`.** Upstream's action table has both `undo-operation` *and* `cancel-operation`, each taking an `s`. The port's `WINDOW_ACTIONS` has `undo-operation` with no parameter and no `cancel-operation`.
- **`win.sort-on` target spelling.** Upstream targets are `"firstname"` and `"surname"`; the port's menu uses `win.sort-on::first-name`. Either side alone works, but they are not the same action state.
- **`<Control>Delete` → `win.delete-marked-contacts`.** Present in upstream's `ShortcutController`; the port binds `Delete` to `delete-contact` instead and has no bulk accelerator.
- **The GOA button in Preferences.** `Adw.ButtonContent` + `Gtk.Button.pill` labelled "_Online Accounts", which calls `launch-panel` on `org.gnome.Settings` over D-Bus. Absent.
- **The camera button in the avatar selector.** `camera_button` "_Take a Picture…" and its `ActionBar` host. Absent by design — no XDG portal binding in ruby-gnome — and documented as such in `avatar_selector.rb`.
- **`data/style.css`.** No `Gtk::CssProvider` anywhere in `lib/`, so 21 upstream classes are attached by nothing and 11 more are never applied: `contacts-sheet`, `contacts-sheet-header`, `contacts-contact-editor`, `contacts-persona-editor`, `contact-editor-group`, `contacts-editor-property`, `contacts-editor-address`, `contacts-property-icon`, `contacts-cutout-button`, `contacts-qr-code-dialog-qr-image`, `contact-list`, `contact-list-row`, `selection-mode`, `edit-icon`, `property`, `header`, `prefixes`, `suffixes`, `title`, `subtitle`, `icon`, `pill`, `devel`.
- **`po/`.** The port has no `po/` directory and no gettext calls; every string is an English literal. Upstream ships 79 locales and a `POTFILES.in` listing 13 `.blp` and 30 `.vala` files.
- **Packaging data.** No `data/` directory: no `.desktop`, no metainfo, no app icons, no GResource (the port needs none, but the desktop file and icon are user-facing).

### Dead code

`lib/gnome_contacts/application.rb` is still the fork scaffold — an
`Adw.StatusPage` reading "The Ruby port has not been written yet." It is not
reachable from `lib/main.rb` and should go.

## Repeaters and conditionals

- **Contact rows** — `contact_list.rb` `list_factory`, one per contact in the selection model; each row carries a `Gtk.CheckButton.selection-mode` revealed only in selection mode, plus upstream's `Gtk.GestureClick` (secondary) and `Gtk.GestureLongPress`, which the port does not attach.
- **Section headers** — upstream's `header_factory` builds one `Gtk.Label.heading.dim-label` per initial letter; the port reproduces it in `contact_list.rb:228`.
- **Editor field rows** — `contact_editor.rb` keeps one blank `Adw.EntryRow` at the end of every multi-value group; typing appends another. Upstream does the same, plus an `Adw.ButtonRow` "show more" behind two nested `Gtk.Revealer`s that the port does not have.
- **Sheet field groups** — upstream adds a group only for chunks the contact has, and inserts a `Gtk.Label` persona-store heading when consecutive chunks come from different personas. The port always renders every group with a placeholder row, and has no persona-store heading.
- **Import dialog** — one `Adw.PreferencesGroup` per file, one `Adw.ActionRow` per parsed contact, one `Gtk.Label.error` per unreadable file; an `Adw.Spinner` while parsing.
- **Address-book rows** — one per EDS source upstream, one per configured backend in the port.
