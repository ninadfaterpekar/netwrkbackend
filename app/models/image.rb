class Image < ApplicationRecord
  has_attached_file :image, styles: {
    medium: '640x640>', thumb: '100x100>'
  }, default_url: '/images/:style/missing.png'
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/
  validates_with AttachmentSizeValidator, attributes: :image,
                                          less_than: 15.megabytes
  belongs_to :message
end
