require 'rails_helper'

RSpec.describe Api::V1::AuthController, type: :controller do
  let(:user) { FactoryBot.create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST #login' do
    context 'with valid credentials' do
      it 'returns a JWT token' do
        post :login, params: { email: user.email, password: 'password123' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']).to include('id', 'name', 'email', 'role')
        expect(json['user']).not_to include('password', 'password_digest')
      end

      it 'works with phone number' do
        user.update!(phone: '555-1234', email: nil)
        post :login, params: { phone: '555-1234', password: 'password123' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post :login, params: { email: user.email, password: 'wrongpassword' }
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end

      it 'returns unauthorized for non-existent user' do
        post :login, params: { email: 'nobody@example.com', password: 'password123' }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with inactive user' do
      it 'returns unauthorized' do
        user.update!(active: false)
        post :login, params: { email: user.email, password: 'password123' }
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Account is inactive')
      end
    end
  end

  describe 'POST #refresh' do
    let(:token) { JwtService.encode(user_id: user.id) }

    context 'with valid token' do
      it 'returns a new token' do
        request.headers['Authorization'] = "Bearer #{token}"
        post :refresh
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['token']).not_to eq(token)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        request.headers['Authorization'] = "Bearer invalid.token"
        post :refresh
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
