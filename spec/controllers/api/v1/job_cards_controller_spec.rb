require 'rails_helper'

RSpec.describe Api::V1::JobCardsController, type: :controller do
  let(:skyview) { FactoryBot.create(:workspace, :skyview) }
  let(:tech_user) { FactoryBot.create(:user, :tech) }
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:job) { FactoryBot.create(:job, :skyview, workspace: skyview) }
  let(:job_card) { job.job_card }
  let!(:job_item) { FactoryBot.create(:job_item, job_card: job_card, quantity: 5) }
  
  before do
    allow(controller).to receive(:current_user).and_return(tech_user)
  end

  describe 'GET #index' do
    let!(:open_job) { FactoryBot.create(:job, :skyview, status: 'open') }
    let!(:closed_job) { FactoryBot.create(:job, :skyview, status: 'closed') }
    let!(:contractor_job) { FactoryBot.create(:job, :contractors) }

    it 'returns open Skyview job cards for tech' do
      get :index
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['job_cards'].size).to eq(2) # includes job from let() + open_job
      expect(json['job_cards'].map { |j| j['id'] }).to include(open_job.job_card.id)
      expect(json['job_cards'].map { |j| j['id'] }).not_to include(closed_job.job_card.id)
    end

    it 'does not return contractor jobs' do
      get :index
      
      json = JSON.parse(response.body)
      expect(json['job_cards'].map { |j| j['id'] }).not_to include(contractor_job.id)
    end
  end

  describe 'GET #show' do
    it 'returns job card details without prices for tech' do
      get :show, params: { id: job_card.id }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      # Should include basic info
      expect(json['id']).to eq(job_card.id)
      expect(json['job']['name']).to eq(job.name)
      expect(json['job']['customer_name']).to eq(job.customer_name)
      expect(json['job']['address']).to eq(job.address)
      
      # Should include items but no prices
      expect(json['job_items'].size).to eq(1)
      expect(json['job_items'][0]['quantity']).to eq(5)
      expect(json['job_items'][0]).not_to have_key('price')
      expect(json['job_items'][0]).not_to have_key('base_price')
    end

    context 'as admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'includes prices for admin' do
        get :show, params: { id: job_card.id }
        
        json = JSON.parse(response.body)
        expect(json['job_items'][0]).to have_key('price')
        expect(json['job_items'][0]['price']).to eq(job_item.master_item.base_price.to_s)
      end
    end

    it 'returns 404 for non-existent job card' do
      get :show, params: { id: SecureRandom.uuid }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH #increment_item' do
    it 'increments item quantity' do
      expect {
        patch :increment_item, params: { id: job_card.id, item_id: job_item.id, delta: 3 }
      }.to change { job_item.reload.quantity }.from(5).to(8)
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['quantity']).to eq(8)
    end

    it 'decrements item quantity' do
      patch :increment_item, params: { id: job_card.id, item_id: job_item.id, delta: -2 }
      
      expect(job_item.reload.quantity).to eq(3)
    end

    it 'does not allow quantity below 0' do
      patch :increment_item, params: { id: job_card.id, item_id: job_item.id, delta: -10 }
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(job_item.reload.quantity).to eq(5) # unchanged
    end

    it 'returns 404 for non-existent item' do
      patch :increment_item, params: { id: job_card.id, item_id: SecureRandom.uuid, delta: 1 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create_custom_entry' do
    it 'creates custom entry without price' do
      expect {
        post :create_custom_entry, params: { 
          id: job_card.id, 
          description: 'Installed outdoor timer',
          quantity: 2
        }
      }.to change { job_card.custom_entries.count }.by(1)
      
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['description']).to eq('Installed outdoor timer')
      expect(json['quantity']).to eq(2)
      expect(json['unit_price']).to be_nil
    end

    it 'validates required fields' do
      post :create_custom_entry, params: { id: job_card.id, quantity: 2 }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']['description']).to include("can't be blank")
    end

    it 'prevents tech from setting price' do
      post :create_custom_entry, params: { 
        id: job_card.id, 
        description: 'Test',
        quantity: 1,
        unit_price: 100
      }
      
      custom_entry = job_card.custom_entries.last
      expect(custom_entry.unit_price).to be_nil # ignored
    end
  end

  describe 'authorization' do
    context 'when not authenticated' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #close' do
    context 'as admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'closes the job card' do
        expect(job_card.closed_at).to be_nil
        
        post :close, params: { id: job_card.id }
        
        expect(response).to have_http_status(:ok)
        job_card.reload
        expect(job_card.closed_at).to be_present
        expect(job_card.job.status).to eq('closed')
      end

      it 'returns error if already closed' do
        job_card.close!
        
        post :close, params: { id: job_card.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Job card is already closed')
      end
    end

    context 'as tech' do
      it 'returns forbidden' do
        post :close, params: { id: job_card.id }
        
        expect(response).to have_http_status(:forbidden)
        expect(job_card.reload.closed_at).to be_nil
      end
    end
  end

  describe 'POST #reopen' do
    let(:closed_job_card) { FactoryBot.create(:job_card, :closed) }

    context 'as admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'reopens the job card' do
        closed_job_card.job.update!(status: 'closed')
        
        post :reopen, params: { id: closed_job_card.id }
        
        expect(response).to have_http_status(:ok)
        closed_job_card.reload
        expect(closed_job_card.closed_at).to be_nil
        expect(closed_job_card.job.status).to eq('open')
      end

      it 'returns error if not closed' do
        post :reopen, params: { id: job_card.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Job card is not closed')
      end

      it 'returns error if job is invoiced' do
        closed_job_card.job.update!(status: 'invoiced')
        
        post :reopen, params: { id: closed_job_card.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Cannot reopen invoiced job')
      end
    end

    context 'as tech' do
      it 'returns forbidden' do
        post :reopen, params: { id: closed_job_card.id }
        
        expect(response).to have_http_status(:forbidden)
        expect(closed_job_card.reload.closed_at).to be_present
      end
    end
  end
end
