# app/controllers/api/v1/photos_controller.rb
module Api
  module V1
    class PhotosController < ApplicationController
      before_action :authenticate_user!
      before_action :set_job
      before_action :set_photo, only: [:destroy, :download]
      before_action :authorize_delete!, only: [:destroy]

      # GET /api/v1/jobs/:job_id/photos
      def index
        photos = @job.photos
        render json: { photos: photos }, status: :ok
      end

      # POST /api/v1/jobs/:job_id/photos
      def create
        if params[:photos].blank?
          render json: { error: 'No photos provided' }, status: :unprocessable_entity
          return
        end

        uploaded_photos = []
        upload_service = PhotoUploadService.new

        begin
          params[:photos].each do |photo_file|
            # Upload to R2
            upload_result = upload_service.upload(@job, photo_file)
            
            # Create Photo record
            photo = @job.photos.create!(
              url: upload_result[:url],
              key: upload_result[:key],
              size: upload_result[:size],
              content_type: upload_result[:content_type],
              uploaded_by: current_user.email
            )
            
            uploaded_photos << photo
          end

          render json: { photos: uploaded_photos }, status: :created
        rescue StandardError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/jobs/:job_id/photos/:id
      def destroy
        upload_service = PhotoUploadService.new
        
        begin
          # Try to delete from R2, but don't fail if it errors
          upload_service.delete(@photo)
        rescue PhotoUploadService::DeletionError => e
          Rails.logger.error "Failed to delete from R2: #{e.message}"
        end
        
        # Always delete from database
        @photo.destroy
        head :no_content
      end

      # GET /api/v1/jobs/:job_id/photos/:id/download
      def download
        redirect_to @photo.url, allow_other_host: true
      end

      private

      def set_job
        @job = Job.find(params[:job_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Job not found' }, status: :not_found
      end

      def set_photo
        @photo = @job.photos.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Photo not found' }, status: :not_found
      end

      def authorize_delete!
        unless current_user.admin?
          render json: { error: 'Only admins can delete photos' }, status: :forbidden
        end
      end
    end
  end
end
