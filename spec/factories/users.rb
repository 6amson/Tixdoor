FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'securepass' } 
    user_type { 'regular' }
    token_jti { SecureRandom.uuid }

    trait :admin do
      user_type { 'admin' }
    end

    trait :regular do
      user_type { 'regular' }
    end
  end
end