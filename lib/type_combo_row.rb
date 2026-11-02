# frozen_string_literal: true

require 'adwaita'
require_relative 'type_set'

# TypeComboRow lets the user pick the label of a field — "Home", "Work",
# "Mobile" — from the TypeSet that applies to it, or type a label of their own.
#
# Ported from upstream's src/contacts-type-combo.vala, which is an Adw.ComboRow
# whose model *is* the TypeSet (upstream's TypeSet implements GListModel) and
# whose expression reads TypeDescriptor.display-name off each item.
#
# Here TypeSet is a plain Ruby object rather than a GListModel, so the model is
# a Gtk::StringList of its labels and the selected index maps back to a
# descriptor through TypeSet#find. Upstream's "Other…" sentinel behaves the
# same: choosing it opens a dialog for a free-form label, which is then kept in
# the model so the row can go on displaying it.
#
class TypeComboRow < Adwaita::ComboRow
  def initialize(type_set, label = nil, &on_change)
    super()
    @type_set = type_set
    @on_change = on_change
    @label = presence(label) || type_set.default.display_name
    self.title = 'Label'
    reload_model
    signal_connect('notify::selected') { on_selected }
  end

  attr_reader :type_set, :label

  # Upstream's selected_descriptor: the TypeDescriptor the row currently shows,
  # custom labels included.
  def selected_descriptor = @type_set.find(@label)

  # The vCard TYPE parameters this label writes, so a caller can serialise the
  # field without knowing whether the label was a built-in or a custom one.
  def vcard_parameters = @type_set.vcard_parameters(@label)

  # Upstream's set_selected_from_vcard_type / set_selected_from_parameters:
  # pick the descriptor that best matches a set of vCard TYPE parameters.
  def select_vcard_types(types)
    self.label = @type_set.lookup_by_vcard_types(Array(types)).display_name
  end

  def label=(value)
    @label = presence(value) || @type_set.default.display_name
    reload_model
  end

  private

  # Rebuilds the model so that it holds the built-in labels, the current custom
  # label when there is one, and the "Other…" sentinel last, then selects the
  # current label without re-entering the change handler.
    def reload_model
      labels.then do |entries|
        @updating = true
        self.model = Gtk::StringList.new(entries)
        self.selected = entries.index(@label) || 0
        @updating = false
      end
    end

    def labels
      if @type_set.index_of(@label)
        @type_set.labels
      else
        @type_set.descriptors.map(&:display_name) + [@label, TypeSet::OTHER_LABEL]
      end
    end

    def on_selected
      unless @updating
        model.get_string(selected).then do |chosen|
          if chosen == TypeSet::OTHER_LABEL
            prompt_for_custom_label
          else
            @label = chosen
            @on_change&.call(@label)
          end
        end
      end
    end

  # Upstream's TypeDescriptor.custom: a label the user typed, which this port
  # stores as X-GOOGLE-LABEL exactly as upstream does.
    def prompt_for_custom_label
      Adwaita::AlertDialog.new('Custom Label', 'Enter a label for this field').tap do |dialog|
        custom_label_entry.tap do |entry|
          dialog.extra_child = entry
          dialog.add_response('cancel', '_Cancel')
          dialog.add_response('save', '_Save')
          dialog.default_response = 'save'
          dialog.close_response = 'cancel'
          dialog.set_response_appearance('save', Adwaita::ResponseAppearance::SUGGESTED)

          dialog.signal_connect('response') do |_, response|
            if response == 'save' && !entry.text.strip.empty?
              self.label = entry.text.strip
              @on_change&.call(@label)
            else
              reload_model
            end
          end

          dialog.present(root)
        end
      end
    end

    def custom_label_entry
      Gtk::Entry.new.tap do |entry|
        if @type_set.find(@label).custom?
          entry.text = @label
        else
          entry.text = ''
        end
        entry.margin_start = 12
        entry.margin_end = 12
        entry.margin_top = 6
        entry.margin_bottom = 6
      end
    end

    def presence(value) = value.to_s.strip.empty? ? nil : value.to_s.strip
end
