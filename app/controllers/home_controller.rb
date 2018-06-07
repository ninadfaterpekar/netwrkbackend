class HomeController < ApplicationController

  def index
    @subscriber = Subscriber.new
  end

  def create_subscriber
=begin
    render plain: params[:subscriber].inspect
=end
    @subscriber = Subscriber.find_by(email: params[:subscriber][:email])
    if @subscriber.present?
      flash[:notice] = 'User already exist...'
      redirect_to root_path
    else
      @subscriber = Subscriber.new(subscriber_params)
      if @subscriber.save
        flash[:notice] = 'Successfully subscribed...'
        redirect_to root_path
      else
        flash[:notice] = 'Sorry something went wrong...'
        redirect_to root_path
      end
    end
  end

  def privacy; end
  def terms_of_use; end
  def loader; end

  def clear_messages
    @messages = Message.all
    @messages.each(&:destroy)
    Image.all.map(&:destroy)
    redirect_to root_path
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:email, :description)
  end
end
