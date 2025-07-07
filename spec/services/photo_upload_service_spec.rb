# spec/services/photo_upload_service_spec.rb
require 'rails_helper'

RSpec.describe PhotoUploadService do
  let(:service) { PhotoUploadService.new }
  let(:job) { create(:job) }
  let(:file) { fixture_file_upload('test_image.jpg', 'image/jpeg') }

  describe '#upload' do
    before do
      # Mock AWS S3 client (used by R2)
      allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
    end

    let(:mock_s3_client) { double('S3Client') }
    let(:mock_response) { double('Response', etag: '"abc123"') }

    it 'uploads file to R2 with correct key structure' do
      expected_key_pattern = %r{jobs/#{job.id}/\d{8}_\d{6}_[a-f0-9]+\.jpg}
      
      expect(mock_s3_client).to receive(:put_object) do |params|
        expect(params[:bucket]).to eq(ENV['R2_BUCKET_NAME'])
        expect(params[:key]).to match(expected_key_pattern)
        expect(params[:content_type]).to eq('image/jpeg')
        expect(params[:body]).to be_present
      end.and_return(mock_response)

      result = service.upload(job, file)
      
      expect(result[:url]).to start_with(ENV['R2_PUBLIC_URL'])
      expect(result[:key]).to match(expected_key_pattern)
      expect(result[:size]).to be > 0
      expect(result[:content_type]).to eq('image/jpeg')
    end

    it 'generates unique keys for simultaneous uploads' do
      keys = []
      
      allow(mock_s3_client).to receive(:put_object).and_return(mock_response)

      3.times do
        result = service.upload(job, file)
        keys << result[:key]
      end

      expect(keys.uniq.size).to eq(3)
    end

    it 'handles different image types' do
      png_file = fixture_file_upload('test_image.png', 'image/png')
      
      expect(mock_s3_client).to receive(:put_object) do |params|
        expect(params[:key]).to end_with('.png')
        expect(params[:content_type]).to eq('image/png')
      end.and_return(mock_response)

      result = service.upload(job, png_file)
      expect(result[:content_type]).to eq('image/png')
    end

    it 'raises error for non-image files' do
      pdf_file = fixture_file_upload('test.pdf', 'application/pdf')
      
      expect {
        service.upload(job, pdf_file)
      }.to raise_error(PhotoUploadService::InvalidContentType)
    end

    it 'raises error when R2 upload fails' do
      allow(mock_s3_client).to receive(:put_object).and_raise(
        Aws::S3::Errors::ServiceError.new(nil, 'Upload failed')
      )

      expect {
        service.upload(job, file)
      }.to raise_error(PhotoUploadService::UploadError)
    end
  end

  describe '#delete' do
    let(:photo) { create(:photo, job: job) }
    let(:mock_s3_client) { double('S3Client') }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
    end

    it 'deletes file from R2' do
      expect(mock_s3_client).to receive(:delete_object).with(
        bucket: ENV['R2_BUCKET_NAME'],
        key: photo.key
      )

      service.delete(photo)
    end

    it 'raises error when deletion fails' do
      allow(mock_s3_client).to receive(:delete_object).and_raise(
        Aws::S3::Errors::ServiceError.new(nil, 'Delete failed')
      )

      expect {
        service.delete(photo)
      }.to raise_error(PhotoUploadService::DeletionError)
    end
  end
end
