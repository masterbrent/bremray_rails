class TemplateItem < ApplicationRecord
  # Associations
  belongs_to :template
  belongs_to :master_item

  # Validations
  validates :template_id, presence: true
  validates :master_item_id, presence: true, uniqueness: { scope: :template_id }
  validates :default_quantity, numericality: { greater_than_or_equal_to: 0 }
end
