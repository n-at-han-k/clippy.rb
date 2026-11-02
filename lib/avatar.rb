# frozen_string_literal: true

require 'adwaita'

# ContactAvatar shows a contact's photo, or a coloured fallback with their
# initials when there is no photo.
#
# Ported from upstream's src/contacts-avatar.vala, which is an Adw.Bin holding
# an Adw.Avatar and a `contact` property: assigning a contact refreshes the
# label, the initials flag and the custom image in one step.
#
# Two deliberate deviations from upstream:
#
#   * the class is ContactAvatar rather than Avatar, because this port already
#     uses Avatar in lib/contact.rb for the *photo* — upstream keeps that on a
#     Folks AvatarChunk, so the name was free there and is not here;
#   * upstream loads the photo asynchronously through Glycin because Folks
#     hands it a GLoadableIcon; here the bytes already travel with the contact,
#     so Avatar#texture decodes them directly and there is nothing to await.
#
class ContactAvatar < Adwaita::Bin
  def initialize(size, contact = nil)
    super()
    @size = size
    self.child = avatar
    self.contact = contact
  end

  attr_reader :size, :contact

  # Upstream ignores a repeated assignment of the same individual so it does
  # not tear down and rebuild the image for nothing.
  def contact=(value)
    unless value.equal?(@contact)
      @contact = value
      update
    end
  end

  # Upstream's find_display_name: prefer a real name for the initials, and when
  # there is none fall back to the display name purely to pick the colour.
  def update
    avatar.tap do |av|
      av.show_initials = !label_name.empty?
      av.text = colour_name
      av.custom_image = @contact&.avatar&.texture
    end
  end

  # Upstream's set_paintable: override the image even when the contact has one
  # of its own, which is how the editor previews a freshly cropped photo.
  def paintable=(paintable)
    avatar.custom_image = paintable
  end

  def size=(value)
    @size = value
    avatar.size = value
  end

  # Memoized widget methods

  def avatar
    @avatar ||= Adwaita::Avatar.new(@size, '', false).tap do |av|
      av.halign = :center
      av.valign = :center
    end
  end

  private

  # The name the initials are drawn from — blank when the contact has nothing
  # better than an email address to be known by.
    def label_name = @contact&.fetch_name.to_s.strip

    def colour_name
      label_name.then { |name| name.empty? ? @contact&.display_name.to_s : name }
    end
end
