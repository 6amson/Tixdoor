FactoryBot.define do
  factory :complaint do
    complaint_type { ['payment_issue', 'service_issue', 'technical_issue', 'other'].sample }
    complain { Faker::Lorem.paragraph }
    status { 'pending' }
    attachment { nil }
    association :user

    trait :with_attachment do
      attachment { 'http://example.com/attachment.png' }
    end

    trait :pending do
      status { 'pending' }
    end

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :resolved do
      status { 'resolved' }
    end

    trait :closed do
      status { 'rejected' }
    end
  end
end
