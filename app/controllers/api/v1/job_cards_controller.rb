module Api
  module V1
    class JobCardsController < ApplicationController
      before_action :set_job_card, only: [:show, :increment_item, :create_custom_entry, :close, :reopen]
      before_action :require_admin, only: [:close, :reopen]

      # GET /api/v1/job_cards
      def index
        job_cards = JobCard
          .joins(job: :workspace)
          .where(jobs: { status: 'open' })
          .where(jobs: { workspace_id: Workspace.skyview&.id })
          .includes(job: :workspace)

        render json: {
          job_cards: job_cards.map { |jc| serialize_job_card_summary(jc) }
        }
      end

      # GET /api/v1/job_cards/:id
      def show
        render json: serialize_job_card_detail(@job_card)
      end

      # PATCH /api/v1/job_cards/:id/increment_item
      def increment_item
        job_item = @job_card.job_items.find_by!(id: params[:item_id])
        new_quantity = job_item.quantity + params[:delta].to_i

        if new_quantity < 0
          render json: { error: 'Quantity cannot be negative' }, status: :unprocessable_entity
        else
          job_item.update!(quantity: new_quantity)
          render json: { id: job_item.id, quantity: job_item.quantity }
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Item not found' }, status: :not_found
      end

      # POST /api/v1/job_cards/:id/custom_entries
      def create_custom_entry
        # Tech can't set price, only description and quantity
        custom_entry = @job_card.custom_entries.build(
          description: params[:description],
          quantity: params[:quantity]
        )

        if custom_entry.save
          render json: serialize_custom_entry(custom_entry), status: :created
        else
          render json: { errors: custom_entry.errors }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/job_cards/:id/close
      def close
        if @job_card.closed_at.present?
          render json: { error: 'Job card is already closed' }, status: :unprocessable_entity
        else
          @job_card.close!
          render json: { 
            id: @job_card.id, 
            closed_at: @job_card.closed_at,
            job_status: @job_card.job.status
          }
        end
      end

      # POST /api/v1/job_cards/:id/reopen
      def reopen
        if @job_card.closed_at.nil?
          render json: { error: 'Job card is not closed' }, status: :unprocessable_entity
        elsif @job_card.job.invoiced?
          render json: { error: 'Cannot reopen invoiced job' }, status: :unprocessable_entity
        else
          @job_card.reopen!
          render json: { 
            id: @job_card.id, 
            closed_at: @job_card.closed_at,
            job_status: @job_card.job.status
          }
        end
      end

      private

      def set_job_card
        @job_card = JobCard.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Job card not found' }, status: :not_found
      end

      def serialize_job_card_summary(job_card)
        {
          id: job_card.id,
          job: {
            name: job_card.job.name,
            customer_name: job_card.job.customer_name,
            address: job_card.job.address
          },
          total_items: job_card.total_items,
          created_at: job_card.created_at
        }
      end

      def serialize_job_card_detail(job_card)
        data = {
          id: job_card.id,
          job: {
            name: job_card.job.name,
            customer_name: job_card.job.customer_name,
            address: job_card.job.address,
            permitted: job_card.job.permitted
          },
          job_items: job_card.job_items.includes(:master_item).map { |item| serialize_job_item(item) },
          custom_entries: job_card.custom_entries.map { |entry| serialize_custom_entry(entry) },
          total_items: job_card.total_items,
          closed_at: job_card.closed_at
        }
        
        data
      end

      def serialize_job_item(job_item)
        data = {
          id: job_item.id,
          master_item: {
            id: job_item.master_item.id,
            code: job_item.master_item.code,
            description: job_item.master_item.description
          },
          quantity: job_item.quantity
        }

        # Only show prices to admins
        if current_user&.admin?
          data[:price] = job_item.master_item.base_price.to_s
        end

        data
      end

      def serialize_custom_entry(custom_entry)
        {
          id: custom_entry.id,
          description: custom_entry.description,
          quantity: custom_entry.quantity,
          unit_price: custom_entry.unit_price
        }
      end
    end
  end
end
