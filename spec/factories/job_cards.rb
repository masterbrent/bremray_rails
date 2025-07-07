FactoryBot.define do
  factory :job_card do
    job

    trait :closed do
      closed_at { 1.hour.ago }
    end

    trait :with_items do
      after(:create) do |job_card|
        3.times do
          master_item = FactoryBot.create(:master_item)
          FactoryBot.create(:job_item, job_card: job_card, master_item: master_item, quantity: rand(0..10))
        end
      end
    end
  end
end
