module Rooms
  class Connect < Mutations::Command
    required do
      model :user
      model :room
    end

    def execute
      connect
      Rooms::CombineSocialMessages.run(user: user, room: room)
    end

    private

    def connect
      room.users << user
      ActionCable.server.broadcast "room_#{room.id}",
                                   socket_type: ChatChannel::TYPE[:user_connect],
                                   user: user.as_json(methods: [:avatar_url])
    end

    def validate
      return unless room.rooms_users.exists?(user: user)
      add_error(:connect, :already_connected, 'User already connected')
    end
  end
end
