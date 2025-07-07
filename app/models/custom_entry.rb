class CustomEntry < ApplicationRecord
  # Associations
  belongs_to :job_card

  # Validations
  validates :job_card_id, presence: true
  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :priced, -> { where.not(unit_price: nil) }
  scope :unpriced, -> { where(unit_price: nil) }
end
