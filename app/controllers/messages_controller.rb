class MessagesController < ApplicationController

  def create
    message = Message.new(message_params)
    message.user = current_user
    if message.save
      ActionCable.server.broadcast 'messages',
        message: message.as_json,
        user: message.user.as_json
      head :ok
    end
  end

  def index
    @messages = Message.all
  end
end
