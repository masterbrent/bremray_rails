require 'rails_helper'

RSpec.describe TemplateItem, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:template_id) }
    it { should validate_presence_of(:master_item_id) }
    it { should validate_numericality_of(:default_quantity).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should belong_to(:template) }
    it { should belong_to(:master_item) }
  end

  describe 'attributes' do
    it 'has default_quantity defaulting to 0' do
      template_item = TemplateItem.new
      expect(template_item.default_quantity).to eq(0)
    end
  end

  describe 'uniqueness' do
    let(:template) { FactoryBot.create(:template) }
    let(:master_item) { FactoryBot.create(:master_item) }

    it 'prevents duplicate template/item combinations' do
      TemplateItem.create!(template: template, master_item: master_item)
      
      duplicate = TemplateItem.new(template: template, master_item: master_item)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:master_item_id]).to include('has already been taken')
    end

    it 'allows same item in different templates' do
      other_template = FactoryBot.create(:template)
      TemplateItem.create!(template: template, master_item: master_item)
      
      other_item = TemplateItem.new(template: other_template, master_item: master_item)
      expect(other_item).to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      template_item = FactoryBot.build(:template_item)
      expect(template_item).to be_valid
    end
  end
end
