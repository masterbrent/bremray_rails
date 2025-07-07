FactoryBot.define do
  factory :job do
    workspace
    name { Faker::Job.title }
    address { Faker::Address.full_address }
    permitted { false }
    permit_fee { 250.00 }
    status { 'open' }

    trait :skyview do
      association :workspace, factory: [:workspace, :skyview]
      customer_name { Faker::Name.name }
    end

    trait :contractors do
      association :workspace, factory: [:workspace, :contractors]
      contractor
    end

    trait :rayno do
      association :workspace, factory: [:workspace, :rayno]
    end

    trait :with_template do
      template
    end

    trait :permitted do
      permitted { true }
    end

    trait :closed do
      status { 'closed' }
    end

    trait :invoiced do
      status { 'invoiced' }
      wave_invoice_id { "INV-#{Faker::Number.number(digits: 6)}" }
    end

    trait :scheduled do
      scheduled_start { 2.days.from_now }
      scheduled_end { 3.days.from_now }
    end
  end
end
