module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    class << self
      attr_accessor :auth_required
    end

    def self.skip_authentication
      self.auth_required = false
    end

    def current_user
      context[:current_user]
    end

    def authenticate_user!
      if self.class.auth_required != false && current_user.nil?
        raise GraphQL::ExecutionError.new("Unauthorized user", extensions: { status: 401, error: "Authentication required." })
      end
    end

    def resolve(**args)
      authenticate_user!
      execute(**args)
    end

    def execute(**)
      raise NotImplementedError, "Subclasses must implement `execute`"
    end
  end
end
