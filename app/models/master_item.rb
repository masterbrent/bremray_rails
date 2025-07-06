class MasterItem < ApplicationRecord
  # Constants
  CATEGORIES = ['General', 'Electrical', 'HVAC', 'Plumbing', 'Structural'].freeze

  # Associations
  has_many :template_items
  has_many :templates, through: :template_items
  has_many :job_items

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :description, presence: true
  validates :base_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
end
