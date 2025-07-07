class Job < ApplicationRecord
  # Associations
  belongs_to :workspace
  belongs_to :template, optional: true
  belongs_to :contractor, optional: true
  has_one :job_card, dependent: :destroy
  has_many :floors, dependent: :destroy
  has_many :photos, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :address, presence: true
  validates :workspace_id, presence: true
  validates :customer_name, presence: true, if: -> { workspace&.slug == 'skyview' }

  # Enums
  enum :status, { open: 0, closed: 1, invoiced: 2 }

  # Scopes
  scope :open, -> { where(status: 'open') }
  scope :closed, -> { where(status: 'closed') }
  scope :invoiced, -> { where(status: 'invoiced') }

  # Callbacks
  after_create :create_job_card_if_needed

  private

  def create_job_card_if_needed
    if workspace.slug == 'skyview' || (workspace.slug == 'rayno' && template.present?)
      create_job_card!
    end
  end
end
