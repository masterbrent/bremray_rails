FactoryBot.define do
  factory :job_item do
    job_card
    master_item
    quantity { 0 }

    trait :with_quantity do
      quantity { rand(1..10) }
    end
  end
end
