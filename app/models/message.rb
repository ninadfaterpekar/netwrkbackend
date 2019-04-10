class Message < ApplicationRecord
  include ActionView::Helpers::DateHelper
  include SetMessageableType

  belongs_to :messageable, polymorphic: true, required: false
  belongs_to :owner, foreign_key: :user_id, class_name: 'User'
  has_many :images, dependent: :destroy
  has_many :videos, dependent: :destroy

  has_many :reports, as: :reportable, dependent: :destroy

  has_many :user_likes, dependent: :destroy
  has_many :liked_users, through: :user_likes, class_name: 'User'

  has_many :locked_messages, dependent: :destroy
  has_many :locked_users, through: :locked_messages, class_name: 'User'

  has_many :user_followed, dependent: :destroy
  has_many :followed_users, through: :user_followed, class_name: 'User'

  has_many :legendary_likes, dependent: :destroy
  has_many :legendary_users, through: :legendary_likes, class_name: 'User'

  has_many :deleted_messages, dependent: :destroy
  has_many :users, through: :deleted_messages

  has_one :room, dependent: :destroy
  has_many :replies, dependent: :destroy

  validates :text, obscenity: { sanitize: true }

  scope :by_ids, ->(ids) { where(id: ids) }
  scope :by_messageable_ids, ->(ids) { where(id: ids) }
  scope :without_blacklist, ->(user) {
    where.not(user_id: user.blacklist.pluck(:target_id))
  }
  scope :by_unlocked, -> { where(locked: false) }
  scope :with_unlocked, ->(user_id) do
    messages = joins(:locked_messages).merge(
      LockedMessage.where(user_id: user_id, unlocked: false)
    )
    where.not(id: messages)
  end
  scope :without_deleted, ->(user) {
    ids_to_exclude = user.messages_deleted.pluck('deleted_messages.message_id')
    without_ids(ids_to_exclude)
  }
  scope :without_ids, ->(ids) { where.not(id: ids) }
  scope :with_images, -> { includes(:images) }
  scope :with_videos, -> { includes(:videos) }
  scope :with_users, -> { includes(:users) }
  scope :undercover_is, ->(bool) { where(undercover: bool) }
  scope :public_is, ->(bool) { where(public: bool) }
  scope :locked_is, ->(bool) { where(locked: bool) }
  scope :by_not_deleted, -> { where(deleted: false) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_social, ->(social) { where(social: social) }
  scope :legendary_messages, -> {
    joins(:legendary_likes).merge(LegendaryLike.where(message_id: ids))
  }
  scope :sort_by_latest_id, -> { order(id: :desc) }
  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_oldest, -> { order(created_at: :asc) }
  scope :sort_by_points_highest, -> { order(points: :desc) }
  scope :by_post_code, ->(post_code) { where(post_code: post_code) }
  scope :by_messageable_type, ->(type) { where(messageable_type: type)}
  scope :by_messageable, ->(id, type = nil) do
    where(messageable_id: id, messageable_type: type)
  end
  scope :by_room, ->(room_id) do
    where(messageable_id: room_id, messageable_type: :Room)
  end
  scope :by_network, ->(network_id) do
    where(messageable_id: network_id, messageable_type: :Network)
  end
  scope :with_room, ->(message_id) do
    joins(:room).merge(Room.where(message_id: message_id))
  end

  scope :sort_by_last_messages, ->(limit, offset) {
    sort_by_newest.limit(limit).offset(offset)
  }

  scope :sort_by_last_messages_id, ->(limit, offset) {
    sort_by_latest_id.limit(limit).offset(offset)
  }

  scope :sort_by_points, ->(limit, offset) {
    sort_by_points_highest.limit(limit).offset(offset)
  }

  URI_REGEX = %r{((?:(?:[^ :/?#]+):)(?://(?:[^ /?#]*))(?:[^ ?#]*)(?:\?(?:[^ #]*))?(?:#(?:[^ ]*))?)}

  attr_accessor :current_user

  def legendary?
    !legendary_count.zero?
  end

  def image_urls
    urls = []
    images.each do |image|
      puts ActionController::Base.helpers.asset_path(image.image.url(:medium))
      urls << (image.url.present? ? image.url : 'https:' + image.image.url(:medium))
    end
    urls
  end

  def video_urls
    urls = []
    videos.each do |video|
      hash = {}
      hash[:poster] = video.thumbnail_url
      hash[:url] = (video.url.present? ? video.url : video.video.url)
      urls << hash
    end
    urls
  end

  def post_url
    post_permalink.present? ? URI.decode(post_permalink) : ''
  end

  def deleted_by_user?(user = current_user)
    users.include?(user)
  end

  def like_by_user(user = current_user)
    liked_users.include?(user)
  end

  def legendary_by_user(user = current_user)
    legendary_users.include?(user)
  end

  def timestamp
    created_at.to_i
  end

  def locked_by_user(user = current_user)

    if locked
      m = LockedMessage.find_by(message_id: id, user_id: user.id)
      m.present? ? !m.unlocked : true
    else
      false
    end
  end

  def is_followed(user = current_user)
    p m = FollowedMessage.find_by(user_id: user, message_id: id)
    m.present? ? true : false
  end

  def is_connected(user = current_user)
    p room_id
    p m = RoomsUser.find_by(user_id: user, room_id: room_id)
    m.present? ? true : false
  end

  def make_locked(args)
    salt = SecureRandom.base64(8)
    update_columns(
      locked: true,
      hint: args[:hint],
      password_salt: salt,
      password_hash: Digest::SHA2.hexdigest(salt + args[:password])
    )
  end

  def make_unlocked(args)
    salt = SecureRandom.base64(8)
    update_columns(
      locked: false,
      hint: args[:hint],
      password_salt: salt,
      password_hash: Digest::SHA2.hexdigest(salt + args[:password])
    )
  end

  def text_with_links
    return if text.nil?
    return text if text.include?('</a>')
    text.split(URI_REGEX).collect do |s|
      valid_url?(s) ? "<a href='#{s}'>#{s}</a>" : s
    end.join
  end

  def valid_url?(uri)
    uri = URI.parse(uri)
    !uri.host.nil?
  rescue
    false
  end

  def correct_password?(password)
    password_hash == Digest::SHA2.hexdigest(password_salt + password)
  end

  def user
    u = User.find_by(id: user_id)
    u.as_json(methods: %i[avatar_url hero_avatar_url], only: %i[name role_name])
  end

  def expire_at
    expire_date.present? ? distance_of_time_in_words(Time.now, expire_date) : ''
  end

  def has_expired
    expire_date.present? && DateTime.now > expire_date
  end

  def post_url=(post_url)
    self.post_permalink = post_url
  end

  def is_synced
    true
  end
end
