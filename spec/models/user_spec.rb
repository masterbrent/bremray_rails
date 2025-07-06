require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:email).allow_nil }
    it { should validate_uniqueness_of(:phone).allow_nil }
    it { should have_secure_password }

    context 'email or phone presence' do
      it 'is invalid without email or phone' do
        user = User.new(name: 'Test User', password: 'password123')
        expect(user).not_to be_valid
        expect(user.errors[:base]).to include('Email or phone must be present')
      end

      it 'is valid with only email' do
        user = User.new(name: 'Test User', email: 'test@example.com', password: 'password123')
        expect(user).to be_valid
      end

      it 'is valid with only phone' do
        user = User.new(name: 'Test User', phone: '555-1234', password: 'password123')
        expect(user).to be_valid
      end

      it 'is valid with both email and phone' do
        user = User.new(name: 'Test User', email: 'test@example.com', phone: '555-1234', password: 'password123')
        expect(user).to be_valid
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(tech: 0, admin: 1) }
  end

  describe 'attributes' do
    it 'has active defaulting to true' do
      user = User.new
      expect(user.active).to eq(true)
    end
  end

  describe '#tech?' do
    it 'returns true for tech role' do
      user = User.new(role: 'tech')
      expect(user.tech?).to be true
      expect(user.admin?).to be false
    end
  end

  describe '#admin?' do
    it 'returns true for admin role' do
      user = User.new(role: 'admin')
      expect(user.admin?).to be true
      expect(user.tech?).to be false
    end
  end

  describe 'password security' do
    it 'does not store plain text password' do
      user = User.create!(name: 'Test', email: 'test@example.com', password: 'secret123')
      expect(user.password_digest).not_to eq('secret123')
      expect(user.password_digest).to be_present
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      user = FactoryBot.build(:user)
      expect(user).to be_valid
    end

    it 'has tech trait' do
      user = FactoryBot.build(:user, :tech)
      expect(user.role).to eq('tech')
    end

    it 'has admin trait' do
      user = FactoryBot.build(:user, :admin)
      expect(user.role).to eq('admin')
    end
  end
end
