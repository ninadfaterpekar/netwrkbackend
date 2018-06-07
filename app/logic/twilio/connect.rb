class Twilio::Connect
  include Service

  def initialize(phone, code)
    @phone = phone
    @code = code
  end

  def perform
    twilio.messages.create(
      from: '+18123016214 ',
      to: phone,
      body: code
    )
  rescue Exception => e
    p e
  end

  private

  attr_reader :phone, :code

  def twilio
    Twilio::REST::Client.new
  end
end
