# spec/factories/photos.rb
FactoryBot.define do
  factory :photo do
    association :job
    url { "https://pub-example.r2.dev/jobs/#{job.id}/20240106_150230_#{SecureRandom.hex(6)}.jpg" }
    key { "jobs/#{job.id}/20240106_150230_#{SecureRandom.hex(6)}.jpg" }
    size { rand(100_000..5_000_000) } # Random size between 100KB and 5MB
    content_type { 'image/jpeg' }
    uploaded_by { 'test@example.com' }
    
    trait :png do
      content_type { 'image/png' }
      url { "https://pub-example.r2.dev/jobs/#{job.id}/20240106_150230_#{SecureRandom.hex(6)}.png" }
      key { "jobs/#{job.id}/20240106_150230_#{SecureRandom.hex(6)}.png" }
    end

    trait :large do
      size { 10_000_000 } # 10MB
    end

    trait :by_admin do
      uploaded_by { 'admin@example.com' }
    end

    trait :by_tech do
      uploaded_by { 'tech@example.com' }
    end
  end
end
