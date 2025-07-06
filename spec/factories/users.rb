FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.unique.phone_number }
    password { 'password123' }
    role { 'tech' }
    active { true }

    trait :tech do
      role { 'tech' }
    end

    trait :admin do
      role { 'admin' }
    end

    trait :inactive do
      active { false }
    end

    trait :email_only do
      phone { nil }
    end

    trait :phone_only do
      email { nil }
    end
  end
end
