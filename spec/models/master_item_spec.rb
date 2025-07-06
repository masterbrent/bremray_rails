require 'rails_helper'

RSpec.describe MasterItem, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:base_price) }
    it { should validate_numericality_of(:base_price).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should have_many(:template_items) }
    it { should have_many(:templates).through(:template_items) }
    it { should have_many(:job_items) }
  end

  describe 'attributes' do
    it 'has active defaulting to true' do
      master_item = MasterItem.new
      expect(master_item.active).to eq(true)
    end

    it 'has unit defaulting to each' do
      master_item = MasterItem.new
      expect(master_item.unit).to eq('each')
    end
  end

  describe 'scopes' do
    let!(:active_item) { FactoryBot.create(:master_item, active: true) }
    let!(:inactive_item) { FactoryBot.create(:master_item, active: false) }

    it 'has active scope' do
      expect(MasterItem.active).to include(active_item)
      expect(MasterItem.active).not_to include(inactive_item)
    end

    it 'has by_category scope' do
      electrical = FactoryBot.create(:master_item, category: 'Electrical')
      plumbing = FactoryBot.create(:master_item, category: 'Plumbing')
      
      expect(MasterItem.by_category('Electrical')).to include(electrical)
      expect(MasterItem.by_category('Electrical')).not_to include(plumbing)
    end
  end

  describe 'categories' do
    it 'has predefined categories' do
      expect(MasterItem::CATEGORIES).to eq(['General', 'Electrical', 'HVAC', 'Plumbing', 'Structural'])
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      master_item = FactoryBot.build(:master_item)
      expect(master_item).to be_valid
    end
  end
end
