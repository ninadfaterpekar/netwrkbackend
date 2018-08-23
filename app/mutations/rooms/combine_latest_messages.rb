module Rooms
	class CombineLatestMessages < Mutations::Command
		required do
	      model :user
	      model :room
	    end

	    def execute
	      combine
	    end

	    private

	    def combine
	      obj = MessageQuery.new(user)
	      obj.latest_message(
	        user, room.message.post_code, room.message.public, 1, 0
	      ).each do |message|
	        new_message = message.dup
	        new_message.update(messageable: room)
	        ActionCable.server.broadcast "room_#{room.id}",
	                                     socket_type: ChatChannel::TYPE[:message],
	                                     message: new_message.as_json(
	                                       methods: %i[
	                                         image_urls locked video_urls user
	                                         is_synced text_with_links post_url
	                                         expire_at has_expired locked_by_user
	                                         timestamp
	                                       ]
	                                     )
	      end
	    end
	end
end
