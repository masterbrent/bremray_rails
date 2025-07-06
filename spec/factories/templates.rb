FactoryBot.define do
  factory :template do
    workspace
    sequence(:name) { |n| "Template #{n}" }
    active { true }

    trait :with_minimum_price do
      minimum_price { 850.00 }
    end

    trait :inactive do
      active { false }
    end

    trait :sunroom do
      name { 'Sunroom' }
    end

    trait :pergola do
      name { 'Pergola' }
      minimum_price { 850.00 }
    end

    trait :with_items do
      after(:create) do |template|
        3.times do
          master_item = FactoryBot.create(:master_item)
          template.add_item(master_item, default_quantity: rand(1..5))
        end
      end
    end
  end
end
