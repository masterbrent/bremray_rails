FactoryBot.define do
  factory :template_item do
    template
    master_item
    default_quantity { 0 }

    trait :with_quantity do
      default_quantity { 5 }
    end
  end
end
