class ApplicationController < ActionController::API
  # API-only controller with JWT authentication
  
  before_action :authenticate_request
  
  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    
    decoded = JwtService.decode(token)
    @current_user = User.find(decoded[:user_id]) if decoded
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def require_admin
    render json: { error: 'Forbidden' }, status: :forbidden unless current_user&.admin?
  end

  def require_tech_or_admin
    render json: { error: 'Forbidden' }, status: :forbidden unless current_user&.tech? || current_user&.admin?
  end

  def skip_authentication
    # Used in before_action skip for public endpoints
  end
end
