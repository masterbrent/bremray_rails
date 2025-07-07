require 'rails_helper'

RSpec.describe "Api::V1::JobCards", type: :request do
  let(:skyview) { FactoryBot.create(:workspace, :skyview) }
  let(:tech_user) { FactoryBot.create(:user, :tech) }
  let(:token) { JwtService.encode(user_id: tech_user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe "tech workflow integration" do
    let(:template) { FactoryBot.create(:template, workspace: skyview) }
    let!(:master_item1) { FactoryBot.create(:master_item, :gfci_outlet) }
    let!(:master_item2) { FactoryBot.create(:master_item, :light_switch) }
    let!(:template_item1) { FactoryBot.create(:template_item, template: template, master_item: master_item1) }
    let!(:template_item2) { FactoryBot.create(:template_item, template: template, master_item: master_item2) }

    it "completes a full tech workflow" do
      # Admin creates job (would be separate endpoint)
      job = FactoryBot.create(:job, workspace: skyview, template: template, 
                             name: "Install outlets", 
                             customer_name: "John Smith",
                             address: "123 Main St, Boulder, CO")

      # Tech views open jobs
      get "/api/v1/job_cards", headers: headers
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json['job_cards'].size).to eq(1)
      job_card_id = json['job_cards'][0]['id']

      # Tech opens job card
      get "/api/v1/job_cards/#{job_card_id}", headers: headers
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json['job_items'].size).to eq(2)
      gfci_item = json['job_items'].find { |i| i['master_item']['code'] == 'GFCI-001' }
      expect(gfci_item['quantity']).to eq(0)

      # Tech installs 4 GFCI outlets
      patch "/api/v1/job_cards/#{job_card_id}/increment_item", 
            params: { item_id: gfci_item['id'], delta: 4 },
            headers: headers
      expect(response).to have_http_status(:ok)

      # Tech adds custom work
      post "/api/v1/job_cards/#{job_card_id}/custom_entries",
           params: { description: "Installed outdoor timer", quantity: 2 },
           headers: headers
      expect(response).to have_http_status(:created)

      # Verify final state
      get "/api/v1/job_cards/#{job_card_id}", headers: headers
      json = JSON.parse(response.body)
      
      gfci_item = json['job_items'].find { |i| i['master_item']['code'] == 'GFCI-001' }
      expect(gfci_item['quantity']).to eq(4)
      expect(json['custom_entries'].size).to eq(1)
      expect(json['custom_entries'][0]['description']).to eq("Installed outdoor timer")
    end
  end

  describe "permission restrictions" do
    it "requires authentication" do
      get "/api/v1/job_cards"
      expect(response).to have_http_status(:unauthorized)
    end

    it "prevents tech from seeing prices" do
      job = FactoryBot.create(:job, :skyview)
      FactoryBot.create(:job_item, job_card: job.job_card)

      get "/api/v1/job_cards/#{job.job_card.id}", headers: headers
      
      json = JSON.parse(response.body)
      expect(json['job_items'][0]).not_to have_key('price')
      expect(json['job_items'][0]).not_to have_key('base_price')
    end
  end

  describe "admin actions" do
    let(:admin_user) { FactoryBot.create(:user, :admin) }
    let(:admin_token) { JwtService.encode(user_id: admin_user.id) }
    let(:admin_headers) { { 'Authorization' => "Bearer #{admin_token}" } }
    let(:job) { FactoryBot.create(:job, :skyview) }

    it "allows admin to close and reopen job cards" do
      # Admin closes job card
      post "/api/v1/job_cards/#{job.job_card.id}/close", headers: admin_headers
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json['closed_at']).to be_present
      expect(json['job_status']).to eq('closed')

      # Tech cannot see closed jobs in index
      get "/api/v1/job_cards", headers: headers
      json = JSON.parse(response.body)
      expect(json['job_cards'].map { |j| j['id'] }).not_to include(job.job_card.id)

      # Admin reopens job card
      post "/api/v1/job_cards/#{job.job_card.id}/reopen", headers: admin_headers
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json['closed_at']).to be_nil
      expect(json['job_status']).to eq('open')

      # Tech can see it again
      get "/api/v1/job_cards", headers: headers
      json = JSON.parse(response.body)
      expect(json['job_cards'].map { |j| j['id'] }).to include(job.job_card.id)
    end

    it "prevents tech from closing job cards" do
      post "/api/v1/job_cards/#{job.job_card.id}/close", headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
