# spec/controllers/api/v1/photos_controller_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::PhotosController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:tech_user) { create(:user, :tech) }
  let(:workspace) { create(:workspace, :skyview) }
  let(:job) { create(:job, workspace: workspace) }
  
  before do
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end

  describe 'POST #create' do
    let(:file) { fixture_file_upload('test_image.jpg', 'image/jpeg') }
    let(:valid_params) { { job_id: job.id, photos: [file] } }

    context 'as admin' do
      let(:current_user) { admin_user }

      it 'creates photos successfully' do
        # Mock R2 upload
        allow_any_instance_of(PhotoUploadService).to receive(:upload).and_return({
          url: 'https://pub-example.r2.dev/jobs/123/test.jpg',
          key: 'jobs/123/test.jpg',
          size: 1024,
          content_type: 'image/jpeg'
        })

        expect {
          post :create, params: valid_params
        }.to change(Photo, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['photos'].length).to eq(1)
        expect(json['photos'][0]['uploaded_by']).to eq(admin_user.email)
      end

      it 'handles multiple photos' do
        files = [
          fixture_file_upload('test_image.jpg', 'image/jpeg'),
          fixture_file_upload('test_image2.jpg', 'image/jpeg')
        ]
        
        allow_any_instance_of(PhotoUploadService).to receive(:upload).and_return({
          url: 'https://pub-example.r2.dev/jobs/123/test.jpg',
          key: 'jobs/123/test.jpg',
          size: 1024,
          content_type: 'image/jpeg'
        })

        expect {
          post :create, params: { job_id: job.id, photos: files }
        }.to change(Photo, :count).by(2)
      end
    end

    context 'as tech' do
      let(:current_user) { tech_user }

      it 'allows photo upload' do
        allow_any_instance_of(PhotoUploadService).to receive(:upload).and_return({
          url: 'https://pub-example.r2.dev/jobs/123/test.jpg',
          key: 'jobs/123/test.jpg',
          size: 1024,
          content_type: 'image/jpeg'
        })

        expect {
          post :create, params: valid_params
        }.to change(Photo, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'error handling' do
      let(:current_user) { admin_user }

      it 'returns error for non-existent job' do
        post :create, params: { job_id: 'non-existent', photos: [file] }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error for missing photos' do
        post :create, params: { job_id: job.id }
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No photos provided')
      end

      it 'handles upload failures' do
        allow_any_instance_of(PhotoUploadService).to receive(:upload)
          .and_raise(StandardError.new('Upload failed'))

        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Upload failed')
      end
    end
  end

  describe 'GET #index' do
    let(:current_user) { admin_user }
    let!(:photo1) { create(:photo, job: job, created_at: 2.days.ago) }
    let!(:photo2) { create(:photo, job: job, created_at: 1.day.ago) }
    let!(:photo3) { create(:photo, job: job) }

    it 'returns photos for the job ordered by newest first' do
      get :index, params: { job_id: job.id }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['photos'].length).to eq(3)
      expect(json['photos'][0]['id']).to eq(photo3.id)
      expect(json['photos'][1]['id']).to eq(photo2.id)
      expect(json['photos'][2]['id']).to eq(photo1.id)
    end

    it 'returns empty array for job with no photos' do
      job_without_photos = create(:job, workspace: workspace)
      get :index, params: { job_id: job_without_photos.id }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['photos']).to eq([])
    end

    it 'returns not found for non-existent job' do
      get :index, params: { job_id: 'non-existent' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:photo) { create(:photo, job: job) }

    context 'as admin' do
      let(:current_user) { admin_user }

      it 'deletes the photo and removes from R2' do
        allow_any_instance_of(PhotoUploadService).to receive(:delete).and_return(true)

        expect {
          delete :destroy, params: { job_id: job.id, id: photo.id }
        }.to change(Photo, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns not found for photo from different job' do
        other_job = create(:job, workspace: workspace)
        other_photo = create(:photo, job: other_job)

        delete :destroy, params: { job_id: job.id, id: other_photo.id }
        expect(response).to have_http_status(:not_found)
      end

      it 'handles R2 deletion failure gracefully' do
        allow_any_instance_of(PhotoUploadService).to receive(:delete)
          .and_raise(StandardError.new('R2 deletion failed'))

        # Should still delete from database
        expect {
          delete :destroy, params: { job_id: job.id, id: photo.id }
        }.to change(Photo, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'as tech' do
      let(:current_user) { tech_user }

      it 'forbids photo deletion' do
        expect {
          delete :destroy, params: { job_id: job.id, id: photo.id }
        }.not_to change(Photo, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #download' do
    let(:current_user) { admin_user }
    let(:photo) { create(:photo, job: job) }

    it 'redirects to the photo URL' do
      get :download, params: { job_id: job.id, id: photo.id }
      expect(response).to redirect_to(photo.url)
    end

    it 'returns not found for non-existent photo' do
      get :download, params: { job_id: job.id, id: 'non-existent' }
      expect(response).to have_http_status(:not_found)
    end

    context 'as tech' do
      let(:current_user) { tech_user }

      it 'allows photo download' do
        get :download, params: { job_id: job.id, id: photo.id }
        expect(response).to redirect_to(photo.url)
      end
    end
  end
end
