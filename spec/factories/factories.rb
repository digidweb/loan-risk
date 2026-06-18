FactoryBot.define do
  factory :loan do
    amount     { Faker::Commerce.price(range: 1_000..50_000) }
    state_code { Loan::BRAZILIAN_STATES.sample }
    status     { "active" }
  end

  factory :concentration_rule do
    scope_type            { "default" }
    scope_value           { nil }
    max_concentration_pct { 0.10 }
    active                { true }
    effective_from        { Date.today }

    trait :for_sp do
      scope_type  { "state" }
      scope_value { "SP" }
      max_concentration_pct { 0.20 }
    end

    trait :for_state do
      scope_type { "state" }
    end
  end
end
