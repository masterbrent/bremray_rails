class JobItem < ApplicationRecord
  # Associations
  belongs_to :job_card
  belongs_to :master_item

  # Validations
  validates :job_card_id, presence: true
  validates :master_item_id, presence: true, uniqueness: { scope: :job_card_id }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
end
