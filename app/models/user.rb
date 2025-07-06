class User < ApplicationRecord
  # Enable bcrypt password hashing
  has_secure_password

  # Enums
  enum :role, { tech: 0, admin: 1 }

  # Validations
  validates :name, presence: true
  validates :email, uniqueness: true, allow_nil: true
  validates :phone, uniqueness: true, allow_nil: true
  validate :email_or_phone_present

  private

  def email_or_phone_present
    if email.blank? && phone.blank?
      errors.add(:base, "Email or phone must be present")
    end
  end
end
