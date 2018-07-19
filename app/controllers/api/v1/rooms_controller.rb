class Api::V1::RoomsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  # POST api/v1/room/:room_id/users/
  def add_user
    room = Room.find(params[:room_id])
    outcome = Rooms::Connect.run(user: current_user, room: room)
    if outcome.success?
      #head :ok
      render json: { message: 'ok' }, status: 200
    else
      render json: { errors: outcome.errors }, status: :bad_request
    end
  end
end
