require 'rails_helper'

RSpec.describe JwtService do
  let(:user) { FactoryBot.create(:user) }
  let(:payload) { { user_id: user.id } }

  describe '.encode' do
    it 'returns a JWT token' do
      token = JwtService.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'includes expiration time' do
      token = JwtService.encode(payload)
      decoded = JWT.decode(token, JwtService.secret, true, algorithm: 'HS256')
      expect(decoded[0]).to have_key('exp')
    end

    it 'accepts custom expiration' do
      exp_time = 1.hour.from_now
      token = JwtService.encode(payload, exp_time)
      decoded = JWT.decode(token, JwtService.secret, true, algorithm: 'HS256')
      expect(decoded[0]['exp']).to eq(exp_time.to_i)
    end
  end

  describe '.decode' do
    it 'returns the original payload' do
      token = JwtService.encode(payload)
      decoded = JwtService.decode(token)
      expect(decoded[:user_id]).to eq(user.id)
    end

    it 'returns nil for invalid token' do
      decoded = JwtService.decode('invalid.token.here')
      expect(decoded).to be_nil
    end

    it 'returns nil for expired token' do
      token = JwtService.encode(payload, 1.second.ago)
      decoded = JwtService.decode(token)
      expect(decoded).to be_nil
    end

    it 'returns nil for nil token' do
      decoded = JwtService.decode(nil)
      expect(decoded).to be_nil
    end
  end

  describe '.secret' do
    it 'uses Rails secret key base in production' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      expect(JwtService.secret).to eq(Rails.application.credentials.secret_key_base)
    end

    it 'uses environment variable if set' do
      ENV['JWT_SECRET'] = 'test_secret'
      expect(JwtService.secret).to eq('test_secret')
      ENV.delete('JWT_SECRET')
    end
  end
end
