# app/services/photo_upload_service.rb
require 'aws-sdk-s3'

class PhotoUploadService
  class InvalidContentType < StandardError; end
  class UploadError < StandardError; end
  class DeletionError < StandardError; end

  ACCEPTED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  def initialize
    @s3_client = Aws::S3::Client.new(
      access_key_id: ENV['R2_ACCESS_KEY_ID'],
      secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
      endpoint: ENV['R2_ENDPOINT'],
      region: 'auto'
    )
    @bucket_name = ENV['R2_BUCKET_NAME']
    @public_url = ENV['R2_PUBLIC_URL']
  end

  def upload(job, file)
    validate_content_type!(file.content_type)
    
    key = generate_key(job, file)
    
    begin
      @s3_client.put_object(
        bucket: @bucket_name,
        key: key,
        body: file.read,
        content_type: file.content_type
      )
      
      {
        url: "#{@public_url}/#{key}",
        key: key,
        size: file.size,
        content_type: file.content_type
      }
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "R2 upload failed: #{e.message}"
      raise UploadError, "Failed to upload photo: #{e.message}"
    end
  end

  def delete(photo)
    begin
      @s3_client.delete_object(
        bucket: @bucket_name,
        key: photo.key
      )
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "R2 deletion failed: #{e.message}"
      raise DeletionError, "Failed to delete photo: #{e.message}"
    end
  end

  private

  def validate_content_type!(content_type)
    unless ACCEPTED_CONTENT_TYPES.include?(content_type)
      raise InvalidContentType, "Invalid content type: #{content_type}. Accepted types: #{ACCEPTED_CONTENT_TYPES.join(', ')}"
    end
  end

  def generate_key(job, file)
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    uuid = SecureRandom.hex(8)
    extension = File.extname(file.original_filename).downcase
    
    "jobs/#{job.id}/#{timestamp}_#{uuid}#{extension}"
  end
end
