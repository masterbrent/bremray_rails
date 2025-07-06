require 'rails_helper'

RSpec.describe Workspace, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe 'associations' do
    it { should have_many(:templates) }
    it { should have_many(:jobs) }
  end

  describe 'database fields' do
    it 'has the correct columns' do
      expect(Workspace.column_names).to include('id', 'name', 'slug', 'settings', 'created_at', 'updated_at')
    end

    it 'has settings as jsonb type' do
      column = Workspace.columns.find { |c| c.name == 'settings' }
      expect(column.type).to eq(:jsonb) if column
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      workspace = FactoryBot.build(:workspace)
      expect(workspace).to be_valid
    end
  end

  describe 'slug validation' do
    it 'only allows lowercase slugs' do
      workspace = Workspace.new(name: 'Test', slug: 'TEST')
      expect(workspace).not_to be_valid
      expect(workspace.errors[:slug]).to include('must be lowercase')
    end

    it 'only allows alphanumeric and hyphens in slug' do
      workspace = Workspace.new(name: 'Test', slug: 'test_workspace')
      expect(workspace).not_to be_valid
      expect(workspace.errors[:slug]).to include('can only contain lowercase letters, numbers, and hyphens')
    end
  end

  describe 'predefined workspaces' do
    it 'has class methods for finding standard workspaces' do
      expect(Workspace).to respond_to(:skyview)
      expect(Workspace).to respond_to(:contractors)
      expect(Workspace).to respond_to(:rayno)
    end
  end
end
