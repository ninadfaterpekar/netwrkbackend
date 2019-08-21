class Api::V1::RoomsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  # POST api/v1/room/:room_id/users/
  def add_user
    room = Room.find(params[:room_id])
    outcome = Rooms::Connect.run(user: current_user, room: room)

    #get line owners private lines count to show coach mark
    user_id = room.message.user_id
    privateLineCount = Message.by_messageable_type('Network')
            .locked_is(true)
            .by_user(user_id)
            .count

    if outcome.success?
      render json: { message: 'ok', privateLineCount: privateLineCount }, status: 200
    else
      render json: { errors: outcome.errors, privateLineCount: privateLineCount }, status: :bad_request
    end
  end

  def get_network
    room = Room.includes(:message).find(params[:room_id])
    message = room.message
    message.current_user = current_user

    if room 
        render json: {
        messages: message.as_json(
          methods: %i[
            image_urls video_urls like_by_user legendary_by_user user
            text_with_links post_url expire_at has_expired
            conversation_status
          ]
        )
      }
    else
      render json: {message: []}, status: 200
    end
  end
end
