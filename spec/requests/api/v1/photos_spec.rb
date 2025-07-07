# spec/requests/api/v1/photos_spec.rb
require 'rails_helper'

RSpec.describe 'Photos API', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:tech_user) { create(:user, :tech) }
  let(:workspace) { create(:workspace, :skyview) }
  let(:job) { create(:job, workspace: workspace) }
  
  let(:admin_headers) { auth_headers(admin_user) }
  let(:tech_headers) { auth_headers(tech_user) }

  before do
    # Mock PhotoUploadService for all tests
    allow_any_instance_of(PhotoUploadService).to receive(:upload).and_return({
      url: 'https://pub-example.r2.dev/jobs/123/test.jpg',
      key: 'jobs/123/test.jpg',
      size: 1024,
      content_type: 'image/jpeg'
    })
    allow_any_instance_of(PhotoUploadService).to receive(:delete).and_return(true)
  end

  describe 'POST /api/v1/jobs/:job_id/photos' do
    let(:file) { Rack::Test::UploadedFile.new('spec/fixtures/files/test_image.jpg', 'image/jpeg') }

    context 'with valid params' do
      it 'uploads photos as admin' do
        post "/api/v1/jobs/#{job.id}/photos", 
             params: { photos: [file] }, 
             headers: admin_headers

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['photos'].length).to eq(1)
        expect(json['photos'][0]['uploaded_by']).to eq(admin_user.email)
        expect(Photo.count).to eq(1)
      end

      it 'uploads photos as tech' do
        post "/api/v1/jobs/#{job.id}/photos", 
             params: { photos: [file] }, 
             headers: tech_headers

        expect(response).to have_http_status(:created)
        expect(Photo.count).to eq(1)
      end

      it 'handles multiple photo uploads' do
        file2 = Rack::Test::UploadedFile.new('spec/fixtures/files/test_image.jpg', 'image/jpeg')
        
        post "/api/v1/jobs/#{job.id}/photos", 
             params: { photos: [file, file2] }, 
             headers: admin_headers

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['photos'].length).to eq(2)
        expect(Photo.count).to eq(2)
      end
    end

    context 'with invalid params' do
      it 'returns error without authentication' do
        post "/api/v1/jobs/#{job.id}/photos", params: { photos: [file] }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error for non-existent job' do
        post "/api/v1/jobs/non-existent/photos", 
             params: { photos: [file] }, 
             headers: admin_headers
        
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error when no photos provided' do
        post "/api/v1/jobs/#{job.id}/photos", 
             params: {}, 
             headers: admin_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No photos provided')
      end
    end
  end

  describe 'GET /api/v1/jobs/:job_id/photos' do
    let!(:photo1) { create(:photo, job: job, created_at: 2.days.ago) }
    let!(:photo2) { create(:photo, job: job, created_at: 1.day.ago) }
    let!(:photo3) { create(:photo, job: job) }

    it 'returns all photos for the job' do
      get "/api/v1/jobs/#{job.id}/photos", headers: admin_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['photos'].length).to eq(3)
      
      # Should be ordered newest first
      expect(json['photos'][0]['id']).to eq(photo3.id)
      expect(json['photos'][1]['id']).to eq(photo2.id)
      expect(json['photos'][2]['id']).to eq(photo1.id)
    end

    it 'returns photos for tech users' do
      get "/api/v1/jobs/#{job.id}/photos", headers: tech_headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns empty array for job without photos' do
      job_without_photos = create(:job, workspace: workspace)
      get "/api/v1/jobs/#{job_without_photos.id}/photos", headers: admin_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['photos']).to eq([])
    end

    it 'returns 404 for non-existent job' do
      get "/api/v1/jobs/non-existent/photos", headers: admin_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/jobs/:job_id/photos/:id' do
    let!(:photo) { create(:photo, job: job) }

    context 'as admin' do
      it 'deletes the photo' do
        expect {
          delete "/api/v1/jobs/#{job.id}/photos/#{photo.id}", headers: admin_headers
        }.to change(Photo, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for photo from different job' do
        other_job = create(:job, workspace: workspace)
        other_photo = create(:photo, job: other_job)

        delete "/api/v1/jobs/#{job.id}/photos/#{other_photo.id}", headers: admin_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'as tech' do
      it 'returns forbidden' do
        expect {
          delete "/api/v1/jobs/#{job.id}/photos/#{photo.id}", headers: tech_headers
        }.not_to change(Photo, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/jobs/:job_id/photos/:id/download' do
    let(:photo) { create(:photo, job: job) }

    it 'redirects to photo URL as admin' do
      get "/api/v1/jobs/#{job.id}/photos/#{photo.id}/download", headers: admin_headers
      
      expect(response).to have_http_status(:redirect)
      expect(response.location).to eq(photo.url)
    end

    it 'redirects to photo URL as tech' do
      get "/api/v1/jobs/#{job.id}/photos/#{photo.id}/download", headers: tech_headers
      
      expect(response).to have_http_status(:redirect)
      expect(response.location).to eq(photo.url)
    end

    it 'returns 404 for non-existent photo' do
      get "/api/v1/jobs/#{job.id}/photos/non-existent/download", headers: admin_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
