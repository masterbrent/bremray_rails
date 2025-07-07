FactoryBot.define do
  factory :contractor do
    company_name { Faker::Company.name }
    contact_name { Faker::Name.name }
    phone { Faker::PhoneNumber.unique.phone_number }
    email { Faker::Internet.email }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
