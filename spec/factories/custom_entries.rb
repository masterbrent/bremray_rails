FactoryBot.define do
  factory :custom_entry do
    job_card
    description { Faker::Lorem.sentence }
    quantity { rand(1..5) }
    unit_price { nil }

    trait :priced do
      unit_price { Faker::Commerce.price(range: 50.0..500.0) }
    end
  end
end
