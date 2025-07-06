class Template < ApplicationRecord
  # Associations
  belongs_to :workspace
  has_many :template_items, dependent: :destroy
  has_many :master_items, through: :template_items

  # Validations
  validates :name, presence: true
  validates :workspace_id, presence: true
  validates :minimum_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Methods
  def add_item(master_item, default_quantity: 0)
    template_items.find_or_create_by(master_item: master_item) do |item|
      item.default_quantity = default_quantity
    end
  end
end
