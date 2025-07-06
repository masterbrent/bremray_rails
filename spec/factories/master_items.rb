FactoryBot.define do
  factory :master_item do
    sequence(:code) { |n| "ITEM-#{n.to_s.rjust(3, '0')}" }
    description { Faker::Commerce.product_name }
    base_price { Faker::Commerce.price(range: 10.0..500.0) }
    category { MasterItem::CATEGORIES.sample }
    unit { 'each' }
    active { true }

    trait :electrical do
      category { 'Electrical' }
    end

    trait :plumbing do
      category { 'Plumbing' }
    end

    trait :inactive do
      active { false }
    end

    # Specific items for testing
    trait :gfci_outlet do
      code { 'GFCI-001' }
      description { 'GFCI Outlet' }
      base_price { 165.00 }
      category { 'Electrical' }
    end

    trait :light_switch do
      code { 'SW-001' }
      description { 'Light Switch' }
      base_price { 25.00 }
      category { 'Electrical' }
    end
  end
end
