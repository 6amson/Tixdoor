class User < ApplicationRecord

    has_secure_password
    include ComplaintConstants

    enum user_type: USER_TYPES
    has_many :complaints, dependent: :destroy
    has_many :complaint_comments, dependent: :destroy

    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 6 }
    validates :user_type, presence: true, inclusion: { in: USER_TYPES.keys.map(&:to_s) }
    validates :token_jti, uniqueness: true, allow_nil: true

    before_create :generate_token_jti
    before_update :generate_token_jti, if: :token_jti_changed?
    before_validation :downcase_email

    def generate_token_jti
      self.token_jti = SecureRandom.uuid
    end

    def downcase_email
      self.email = email.downcase if email.present?
    end
end
