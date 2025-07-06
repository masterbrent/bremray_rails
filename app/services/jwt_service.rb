class JwtService
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret, 'HS256')
  end

  def self.decode(token)
    return nil unless token
    
    decoded = JWT.decode(token, secret, true, algorithm: 'HS256')[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.secret
    ENV['JWT_SECRET'] || Rails.application.credentials.secret_key_base
  end
end
