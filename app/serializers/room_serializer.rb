class RoomSerializer < BaseSerializer
  attributes :id
  attribute :messages, if: -> { scopes?(:with_messages) }
  attribute :users,    if: -> { scopes?(:with_users) }

  def messages
    object.messages.as_json
  end

  def users
    object.users.as_json
  end
end
