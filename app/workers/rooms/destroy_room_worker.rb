module Rooms
  class DestroyWorker
    include Sidekiq::Worker

    def perform(room_id)
      room = Room.find(room_id)
      room.destroy
    rescue ActiveRecord::RecordNotFound => e
      p e
    end
  end
end