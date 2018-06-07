class ChatChannel < ApplicationCable::Channel
  TYPE = {
    message: 'message',
    room: 'room',
    user_connect: 'user_connect'
  }.freeze

  def subscribed # (zip_code)
    stream_from "messages#{params[:post_code]}chat"
  end
end
