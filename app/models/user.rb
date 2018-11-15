class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable # , :validatable

  # validates_presence_of :first_name, :last_name, :phone
  validates :name, :role_name, :first_name, :last_name, obscenity: true
  # validates_uniqueness_of :phone
  validates_uniqueness_of :email

  has_many :posts
  has_many :reports, as: :reportable, dependent: :destroy
  # has_and_belongs_to_many :networks
  has_many :rooms_users, dependent: :destroy

  has_many :networks_users, dependent: :destroy
  has_many :networks, through: :networks_users
  has_many :networks_cities, through: :networks, source: :city, class_name: 'City'

  has_many :blacklist, foreign_key: :user_id, class_name: 'Blacklist', dependent: :destroy
  has_many :blacklist_users, through: :blacklist, source: :target, class_name: 'User'
  #
  has_many :deleted_messages, dependent: :destroy
  has_many :messages_deleted, through: :deleted_messages, class_name: 'Message'

  has_many :locked_messages, dependent: :destroy
  has_many :messages_locked, through: :locked_messages, class_name: 'Message'

  has_many :user_followed, dependent: :destroy
  has_many :followed_messages, through: :user_followed, class_name: 'Message'

  has_many :user_likes, dependent: :destroy
  has_many :liked_messages, through: :user_likes, class_name: 'Message'

  has_many :legendary_likes, dependent: :destroy
  has_many :legendary_messages, through: :legendary_likes, class_name: 'Message'

  has_many :messages, dependent: :destroy
  has_many :providers, dependent: :destroy

  before_create :generate_authentication_token!
  after_create :send_welcome_email

  enum gender: %i[male female]

  has_attached_file :avatar, styles: {
    medium: '256x256#', thumb: '100x100>'
  }, default_url: '/images/missing.png'
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\z/

  has_attached_file :hero_avatar, styles: {
    medium: '256x256#', thumb: '100x100>'
  }, default_url: '/images/missing.png'
  validates_attachment_content_type :hero_avatar, content_type: /\Aimage\/.*\z/

  scope :by_auth_token, ->(key) { where(auth_token: key) }
  scope :from_network, ->(network_id) {
    joins(:networks).merge(Network.find(network_id).networks_users.where(connected: true))
  }

  attr_accessor :current_user

  def generate_authentication_token!
    begin
      self.auth_token = Devise.friendly_token
    end while self.class.exists?(auth_token: auth_token)
  end

  def connected_networks
    providers.pluck(:name)
  end

  def avatar_url
    'https:' + avatar.url(:medium)
  end

  def blocked(user = current_user)
    Blacklist.exists?(user_id: user.id, target_id: id)
  end

  def hero_avatar_url
    hero_avatar.exists? ? ('https:' + hero_avatar.url(:medium)) : role_image_url
  end

  def able_to_post_legendary?
    legendary_at.nil? || legendary_days >= 30
  end

  def legendary_days
    (DateTime.now.to_date - legendary_at.to_date).to_i
  end

  def log_in_count
    sign_in_count
  end

  def is_password_set
    encrypted_password
  end

  def disabled_hero?
    points_count <= -200
  end

  def fb_connected
    Provider.find_by(name: 'fb', user_id: id).present?
  end

  def tou_accepted
    terms_of_use_accepted
  end

  def send_welcome_email
=begin
    TemplatesMailer.welcome(email).deliver_now
=end  
  end
end
