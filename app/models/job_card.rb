class JobCard < ApplicationRecord
  # Associations
  belongs_to :job
  has_many :job_items, dependent: :destroy
  has_many :custom_entries, dependent: :destroy
  has_many :photos, dependent: :destroy

  # Validations
  validates :job_id, presence: true

  # Callbacks
  after_create :populate_from_template

  # Instance methods
  def total_items
    job_items.sum(:quantity)
  end

  def close!
    update!(closed_at: Time.current)
    job.update!(status: 'closed')
  end

  def reopen!
    update!(closed_at: nil)
    job.update!(status: 'open')
  end

  private

  def populate_from_template
    return unless job.template

    job.template.template_items.each do |template_item|
      job_items.create!(
        master_item: template_item.master_item,
        quantity: 0
      )
    end
  end
end
