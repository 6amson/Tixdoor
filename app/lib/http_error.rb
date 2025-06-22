class HttpError < StandardError
  attr_reader :status

  def initialize(message = "Something went wrong", status: HttpStatus::INTERNAL_SERVER_ERROR)
    super(message)
    @status = status
  end
end
