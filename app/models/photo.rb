# app/models/photo.rb
class Photo < ApplicationRecord
  belongs_to :job

  validates :url, presence: true
  validates :key, presence: true, uniqueness: true
  validates :size, presence: true
  validates :content_type, presence: true
  validates :uploaded_by, presence: true
  
  validate :content_type_must_be_image

  # Default scope to order by newest first
  default_scope { order(created_at: :desc) }

  # Accepted content types
  ACCEPTED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  def filename
    key.split('/').last
  end

  def size_in_mb
    (size.to_f / 1_048_576).round(1)
  end

  def image?
    ACCEPTED_CONTENT_TYPES.include?(content_type)
  end

  private

  def content_type_must_be_image
    unless ACCEPTED_CONTENT_TYPES.include?(content_type)
      errors.add(:content_type, 'must be an image (jpeg, png, gif, or webp)')
    end
  end
end
