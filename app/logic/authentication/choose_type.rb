class Authentication::ChooseType
  include Service

  def initialize(args)
    @login = args[:login]
    @country_code = args[:country_code]
  end

  def perform
    send_code
  end

  private

  attr_reader :login, :country_code

  def send_code
    code = generate_code
    if ValidateEmail.valid?(login)
      UserMailer.confirmation_mail(login, code).deliver_now
      {
        login_type: 'email',
        login_message: 'Confirmation email is sent',
        login_code: code
      }
      # TODO: email sending
    elsif Phonelib.valid_for_country?(login, country_code)
      Twilio::Connect.new(login, code).perform
      {
        login_type: 'phone',
        login_message: 'Confirmation SMS is sent',
        login_code: code
      }
      # TODO: sms sending
    else
      { login_type: 'error', login_message: 'Your login is incorrect' }
    end
  end

  def generate_code
    rand(100000..999999)
  end
end
