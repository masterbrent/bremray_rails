module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:login]

      def login
        user = find_user_by_credentials
        
        if user&.authenticate(params[:password])
          if user.active?
            token = JwtService.encode(user_id: user.id)
            render json: { 
              token: token, 
              user: user_attributes(user)
            }, status: :ok
          else
            render json: { error: 'Account is inactive' }, status: :unauthorized
          end
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      def refresh
        if current_user
          token = JwtService.encode(user_id: current_user.id)
          render json: { 
            token: token,
            user: user_attributes(current_user)
          }, status: :ok
        else
          render json: { error: 'Invalid token' }, status: :unauthorized
        end
      end

      private

      def find_user_by_credentials
        if params[:email].present?
          User.find_by(email: params[:email])
        elsif params[:phone].present?
          User.find_by(phone: params[:phone])
        end
      end

      def user_attributes(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role
        }
      end
    end
  end
end
