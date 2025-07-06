require 'rails_helper'

RSpec.describe Template, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:workspace_id) }
  end

  describe 'associations' do
    it { should belong_to(:workspace) }
    it { should have_many(:template_items).dependent(:destroy) }
    it { should have_many(:master_items).through(:template_items) }
  end

  describe 'attributes' do
    it 'has active defaulting to true' do
      template = Template.new
      expect(template.active).to eq(true)
    end

    it 'allows minimum_price to be nil' do
      template = FactoryBot.build(:template, minimum_price: nil)
      expect(template).to be_valid
    end

    it 'validates minimum_price is non-negative when present' do
      template = FactoryBot.build(:template, minimum_price: -100)
      expect(template).not_to be_valid
      expect(template.errors[:minimum_price]).to include('must be greater than or equal to 0')
    end
  end

  describe 'scopes' do
    let!(:active_template) { FactoryBot.create(:template, active: true) }
    let!(:inactive_template) { FactoryBot.create(:template, active: false) }

    it 'has active scope' do
      expect(Template.active).to include(active_template)
      expect(Template.active).not_to include(inactive_template)
    end
  end

  describe 'workspace association' do
    it 'requires a valid workspace' do
      template = Template.new(name: 'Test Template', workspace_id: SecureRandom.uuid)
      expect(template).not_to be_valid
      expect(template.errors[:workspace]).to include('must exist')
    end
  end

  describe '#add_item' do
    let(:template) { FactoryBot.create(:template) }
    let(:master_item) { FactoryBot.create(:master_item) }

    it 'adds a master item to the template' do
      expect {
        template.add_item(master_item, default_quantity: 5)
      }.to change { template.template_items.count }.by(1)
      
      template_item = template.template_items.last
      expect(template_item.master_item).to eq(master_item)
      expect(template_item.default_quantity).to eq(5)
    end

    it 'defaults quantity to 0 if not specified' do
      template.add_item(master_item)
      template_item = template.template_items.last
      expect(template_item.default_quantity).to eq(0)
    end

    it 'does not duplicate items' do
      template.add_item(master_item)
      expect {
        template.add_item(master_item)
      }.not_to change { template.template_items.count }
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      template = FactoryBot.build(:template)
      expect(template).to be_valid
    end

    it 'has sunroom trait' do
      template = FactoryBot.build(:template, :sunroom)
      expect(template.name).to eq('Sunroom')
      expect(template.minimum_price).to be_nil
    end

    it 'has pergola trait' do
      template = FactoryBot.build(:template, :pergola)
      expect(template.name).to eq('Pergola')
      expect(template.minimum_price).to eq(850.00)
    end
  end
end
