module Rooms
  class FindOrCreate < Mutations::Command
    required do
      model :message
    end

    def execute
      return room if find_room
      create_room
      #Rooms::CombineSocialMessages.run(user: room.owner, room: room)
    end

    private

    attr_reader :room

    def find_room
      @room = Room.find_by(message: message)
    end

    def create_room
      @room = Room.new(message: message)
      room.users << room.message.owner
      room.save
    end

    def validate
      #return if message.undercover && message.messageable_type != 'Room'
      return if message.messageable_type != 'Room'
      add_error('400', :bad_request, 'cant create room for this message')
    end
  end
end
