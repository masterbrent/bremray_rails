class Workspace < ApplicationRecord
  # Associations
  has_many :templates, dependent: :destroy
  has_many :jobs, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { 
    with: /\A[a-z0-9\-]+\z/,
    message: 'can only contain lowercase letters, numbers, and hyphens'
  }
  validates :slug, format: {
    with: /\A[a-z]/,
    message: 'must be lowercase'
  }

  # Class methods for finding standard workspaces
  def self.skyview
    find_by(slug: 'skyview')
  end

  def self.contractors
    find_by(slug: 'contractors')
  end

  def self.rayno
    find_by(slug: 'rayno')
  end
end
