class UserMailer < ApplicationMailer
  def invitation_mail(name, email)
    @name = name
    @email = email
    mail(to: @email, subject: 'Invitation for Sign Up')
  end

  def greetings_mail(user)
    @name = user.name
    @email = user.email
    mail(to: @email, subject: 'Invitation for Sign Up')
  end

  def confirmation_mail(email, code)
    @email = email
    @code = code
    mail(to: @email, subject: 'Your confirmation code...')
  end

  def legendary_mail(user_id)
    @user = User.find_by(id: user_id)
    @email = @user.email
    mail(to: @email, subject: 'Your message became legendary...')
  end

  def founder_mail(user_id)
    @user = User.find_by(id: user_id)
    @email = @user.email
    mail(to: @email, subject: 'Your are network founder...')
  end

  def connect_mail(user_id)
    @user = User.find_by(id: user_id)
    @email = @user.email
    mail(to: @email, subject: 'Your are joined new network...')
  end

  # def sign_up(user_id, body)
  #   @user = User.find_by(id: user_id)
  #   @body = body
  #   mail(to: @user.email, subject: 'Sign up')
  # end
end
