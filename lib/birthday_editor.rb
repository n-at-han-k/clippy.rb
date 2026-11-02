# frozen_string_literal: true

require 'adwaita'
require 'date'

# BirthdayEditor is the dialog that sets or clears a contact's birthday.
#
# Ported from upstream's data/ui/contacts-birthday-editor.blp and the
# BirthdayEditor class at the end of src/contacts-contact-editor.vala: a day
# spin row, a month combo row, a year spin row, Cancel and Set in the header
# bar, and a destructive "Remove Birthday" row that only appears when the
# contact already has one.
#
# Like upstream, the day's upper bound follows the chosen month and year, so
# 31 February can never be entered. Upstream stores a UTC GLib.DateTime; this
# port stores a Date, which is what Contact#birthday holds.
#
class BirthdayEditor < Adwaita::Dialog
  # Upstream formats the month names from a GLib.DateTime so they follow the
  # locale; Date::MONTHNAMES is the same list for the C locale this port runs
  # in, with its leading nil dropped.
  MONTHS = Date::MONTHNAMES.compact.freeze

  # Upstream's month_of_31: the zero-based indices of the 30-day months.
  MONTHS_OF_30 = [3, 5, 8, 10].freeze

  def initialize(birthday, on_changed)
    super()
    @birthday = coerce(birthday)
    @on_changed = on_changed
    self.title = 'Set Birthday'
    self.content_width = 360
  end

  attr_reader :birthday

  def build
    tap do |dialog|
      dialog.child = toolbar_view

      toolbar_view.tap do |tv|
        tv.add_top_bar(header_bar)
        tv.content = page

        header_bar.tap do |hb|
          hb.pack_start(cancel_button)
          hb.pack_end(set_button)

          cancel_button.signal_connect('clicked') { close }
          set_button.signal_connect('clicked') { apply }
        end

        page.tap do |p|
          p.add(date_group)
          p.add(remove_group)

          date_group.tap do |group|
            group.add(day_row)
            group.add(month_row)
            group.add(year_row)

            month_row.signal_connect('notify::selected') { update_day_range }
            year_row.signal_connect('notify::value') { update_day_range }
          end

          remove_group.tap do |group|
            group.add(remove_row)
            group.visible = !@birthday.nil?

            remove_row.signal_connect('activated') { remove }
          end
        end
      end

      # Upstream seeds the rows from the existing birthday, or from today when
      # the contact has none.
      starting_date.tap do |date|
        year_row.value = date.year
        month_row.selected = date.month - 1
        day_row.value = date.day
      end

      update_day_range
    end
  end

  # Memoized widget methods

  def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new

  def header_bar
    @header_bar ||= Adwaita::HeaderBar.new.tap do |hb|
      hb.show_start_title_buttons = false
      hb.show_end_title_buttons = false
    end
  end

  def page = @page ||= Adwaita::PreferencesPage.new
  def date_group = @date_group ||= Adwaita::PreferencesGroup.new
  def remove_group = @remove_group ||= Adwaita::PreferencesGroup.new

  def cancel_button
    @cancel_button ||= Gtk::Button.new.tap do |btn|
      btn.label = '_Cancel'
      btn.use_underline = true
      btn.can_shrink = true
    end
  end

  def set_button
    @set_button ||= Gtk::Button.new.tap do |btn|
      btn.label = '_Set'
      btn.use_underline = true
      btn.can_shrink = true
      btn.receives_default = true
      btn.add_css_class('suggested-action')
    end
  end

  def day_row
    @day_row ||= Adwaita::SpinRow.new(day_adjustment, 1, 0).tap do |row|
      row.title = 'Day'
      row.numeric = true
    end
  end

  # Upstream's adjustments come from the blueprint: the day starts at 1..31 and
  # is narrowed by update_date, the year spans 1800..3000.
  def day_adjustment
    @day_adjustment ||= Gtk::Adjustment.new(
      1,
      1,
      31,
      1,
      5,
      0,
    )
  end

  def month_row
    @month_row ||= Adwaita::ComboRow.new.tap do |row|
      row.title = 'Month'
      row.model = Gtk::StringList.new(MONTHS)
    end
  end

  def year_row
    @year_row ||= Adwaita::SpinRow.new(year_adjustment, 1, 0).tap do |row|
      row.title = 'Year'
      row.numeric = true
    end
  end

  def year_adjustment
    @year_adjustment ||= Gtk::Adjustment.new(
      2000,
      1800,
      3000,
      1,
      10,
      0,
    )
  end

  def remove_row
    @remove_row ||= Adwaita::ButtonRow.new.tap do |row|
      row.title = 'Remove Birthday'
      row.add_css_class('destructive-action')
    end
  end

  private

    def starting_date = @birthday || Date.today

  # Upstream's update_date: clamp the day to the length of the selected month,
  # leap years included.
    def update_day_range
      days_in_month.then do |limit|
        day_row.adjustment.upper = limit
        if day_row.value > limit
          day_row.value = limit
        end
      end
    end

    def days_in_month
      if MONTHS_OF_30.include?(month_row.selected)
        30
      elsif month_row.selected == 1
        leap_year? ? 29 : 28
      else
        31
      end
    end

    def leap_year? = Date.leap?(selected_year)

    def selected_year = year_row.value.to_i

    def apply
      Date.new(selected_year, month_row.selected + 1, day_row.value.to_i).then do |date|
        @birthday = date
        @on_changed.call(date)
        close
      end
    end

    def remove
      @birthday = nil
      @on_changed.call(nil)
      close
    end

    def coerce(value)
      case value
      when Date then value
      when String then parse(value)
      end
    end

    def parse(value)
      Date.parse(value)
    rescue ArgumentError, TypeError
      nil
    end
end
