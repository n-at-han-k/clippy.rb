# frozen_string_literal: true

require 'adwaita'

# AccountsList lists the address books the app knows about and lets the user
# pick the primary one — the book new contacts are written to.
#
# Ported from upstream's src/contacts-accounts-list.vala, an Adw.PreferencesGroup
# of Adw.ActionRows, one per address book, each carrying a provider icon, the
# book's name, the account it belongs to, and a checkmark that marks the
# primary one. Activating a row makes that book primary.
#
# Upstream's address books are Folks PersonaStores arriving through a filtered
# GListModel, so it drives the checkmarks from a Gtk.SingleSelection over that
# model. This port's address books are backend objects handed over as a plain
# array, so the selection is an index into that array; the row behaviour —
# checkmark as the activatable widget, exactly one marked — is the same.
#
class AccountsList < Adwaita::PreferencesGroup
  def initialize(backends, primary: nil, on_selected: nil)
    super()
    @backends = Array(backends)
    @on_selected = on_selected
    @selected = primary || @backends.first
    self.title = 'Address Books'
    self.description = 'New contacts are added to the selected address book'
  end

  attr_reader :backends

  # Upstream's selected_store: the chosen address book, or nil when the user
  # has no address books at all.
  def selected_backend = @selected

  def build
    tap do |group|
      rows.each { |backend, row| group.add(row.tap { update_row(backend, row) }) }
    end
  end

  def selected_backend=(backend)
    @selected = backend
    rows.each { |other, row| update_row(other, row) }
    @on_selected&.call(backend)
  end

  # One row per address book, built once and kept so the checkmarks can be
  # refreshed when the selection moves.
  def rows
    @rows ||= @backends.to_h { |backend| [backend, address_book_row(backend)] }
  end

  def checkmarks
    @checkmarks ||= @backends.to_h { |backend| [backend, checkmark_for(backend)] }
  end

  private

    def address_book_row(backend)
      Adwaita::ActionRow.new.tap do |row|
        row.title = backend.display_name
        row.subtitle = backend.location.to_s
        row.subtitle_lines = 2
        row.activatable = true
        row.add_prefix(provider_image)

        checkmarks[backend].tap do |checkmark|
          row.add_suffix(checkmark)
          row.activatable_widget = checkmark
        end

        row.signal_connect('activated') { self.selected_backend = backend }
      end
    end

  # Upstream asks GOA for the icon of the online account backing the address
  # book and falls back to the app icon; this port has no online accounts, so
  # every book gets the app icon at the same large size upstream uses.
    def provider_image
      Gtk::Image.new(icon_name: 'address-book-new-symbolic').tap do |image|
        image.icon_size = :large
      end
    end

    def checkmark_for(backend)
      Gtk::Image.new(icon_name: 'object-select-symbolic').tap do |image|
        image.valign = :center
        image.visible = backend.equal?(@selected)
      end
    end

  # A read-only book can be listed but never made primary, which is upstream's
  # reason for filtering its model down to the writable E-D-S stores.
    def update_row(backend, row)
      checkmarks[backend].visible = backend.equal?(@selected)
      row.sensitive = !backend.readonly?
    end
end
