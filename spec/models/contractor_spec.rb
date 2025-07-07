require 'rails_helper'

RSpec.describe Contractor, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:company_name) }
    it { should validate_presence_of(:phone) }
    it { should validate_uniqueness_of(:phone) }
  end

  describe 'associations' do
    it { should have_many(:jobs) }
  end

  describe 'attributes' do
    it 'has active defaulting to true' do
      contractor = Contractor.new
      expect(contractor.active).to eq(true)
    end
  end

  describe 'callbacks' do
    it 'generates access token on create' do
      contractor = FactoryBot.create(:contractor)
      expect(contractor.access_token).to be_present
      expect(contractor.access_token.length).to be >= 32
    end

    it 'generates unique access tokens' do
      contractor1 = FactoryBot.create(:contractor)
      contractor2 = FactoryBot.create(:contractor)
      expect(contractor1.access_token).not_to eq(contractor2.access_token)
    end
  end

  describe 'scopes' do
    let!(:active) { FactoryBot.create(:contractor, active: true) }
    let!(:inactive) { FactoryBot.create(:contractor, active: false) }

    it 'has active scope' do
      expect(Contractor.active).to include(active)
      expect(Contractor.active).not_to include(inactive)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      contractor = FactoryBot.build(:contractor)
      expect(contractor).to be_valid
    end
  end
end
