FactoryBot.define do
  factory :workspace do
    sequence(:name) { |n| "Workspace #{n}" }
    sequence(:slug) { |n| "workspace-#{n}" }
    settings { {} }

    trait :skyview do
      name { "Skyview" }
      slug { "skyview" }
      settings { { "invoice_prefix" => "SKY" } }
    end

    trait :contractors do
      name { "Contractors" }
      slug { "contractors" }
      settings { { "enable_floors" => true, "enable_rooms" => true } }
    end

    trait :rayno do
      name { "Rayno" }
      slug { "rayno" }
      settings { { "flexible_mode" => true } }
    end
  end
end
