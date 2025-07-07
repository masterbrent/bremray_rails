class Contractor < ApplicationRecord
  # Associations
  has_many :jobs

  # Validations
  validates :company_name, presence: true
  validates :phone, presence: true, uniqueness: true

  # Callbacks
  before_create :generate_access_token

  # Scopes
  scope :active, -> { where(active: true) }

  private

  def generate_access_token
    self.access_token = SecureRandom.urlsafe_base64(32)
  end
end
