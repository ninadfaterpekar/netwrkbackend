class MessageQuery
  def initialize(current_user)
    @current_user = current_user
  end

  def from_socials(limit, offset, socials = %w[facebook twitter instagram])
    Message.by_user(current_user.id)
           .by_social(socials)
           .by_post_code(nil).by_messageable(nil)
           .sort_by_last_messages(limit, offset)
  end

  def profile(user, post_code, method, limit, offset)
    Message.by_user(user.id)
           .by_post_code(post_code)
           .by_messageable_type(:Network)
           .public_is(method)
           .sort_by_last_messages(limit, offset)
           .by_not_deleted
           .without_blacklist(user)
           .with_unlocked(current_user.id)
  end

  def latest_message(user, post_code, method, limit, offset)
    Message.by_user(user.id)
           .by_post_code(post_code)
           .by_messageable_type(:Network)
           .public_is(method)
           .sort_by_last_messages_id(limit, offset)
           .by_not_deleted
           .without_blacklist(user)
           .with_unlocked(current_user.id)
  end

  private

  attr_reader :current_user
end
