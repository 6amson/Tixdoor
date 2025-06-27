class AppSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
#   use ApolloUploadServer::Middleware
  # Enable batch loading
  use GraphQL::Batch

  # Handle errors
  rescue_from(ActiveRecord::RecordNotFound) do |err, obj, args, ctx, field|
    GraphQL::ExecutionError.new("#{field.type.unwrap.graphql_name} not found")
  end

  rescue_from(HttpError) do |err, obj, args, ctx, field|
    GraphQL::ExecutionError.new(err.message)
  end

  def self.unauthorized_object(error)
    GraphQL::ExecutionError.new("An object of type #{error.type.graphql_name} was hidden due to permissions")
  end

  def self.unauthorized_field(error)
    GraphQL::ExecutionError.new("The field #{error.field.graphql_name} is not accessible.")
  end

  def self.unauthorized_connection(error)
    GraphQL::ExecutionError.new("The connection #{error.connection.graphql_name} is not accessible.")
  end
end
