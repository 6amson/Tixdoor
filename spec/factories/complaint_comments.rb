FactoryBot.define do
  factory :complaint_comment do
    comment { Faker::Lorem.sentence }
    user_email { Faker::Internet.email }
    user_type { 'admin' }
    association :complaint

    trait :admin_comment do
      user_type { 'admin' }
    end

    trait :user_comment do
      user_type { 'regular' }
    end
  end
end