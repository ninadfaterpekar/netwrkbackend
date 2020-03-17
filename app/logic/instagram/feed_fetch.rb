class Instagram::FeedFetch
  include Service

  def initialize(user, amount_of_posts)
    @user = user
    @amount_of_posts = amount_of_posts
  end

  def perform
    return unless fetch_feed
    save_messages
  end

  private

  attr_reader :user, :amount_of_posts, :feed

  def fetch_feed
    provider = Provider.find_by(user_id: user.id, name: 'instagram')
    return false if provider.nil?
    begin
      if provider.secret.nil?
        # get access token
        client_id = '177347736690442'
        client_secret = 'e3f0665dd859c85dd94182ef11857d50'
        callback_url = 'https://api.somvo.app/loader'

        Instagram.configure do |config|
          config.client_id = client_id
          config.client_secret = client_secret
          # For secured endpoints only
          #config.client_ips = '<Comma separated list of IPs>'
        end

        response = Instagram.get_access_token(provider.token, :redirect_uri => callback_url)
        provider.update_attributes(secret: response.access_token)

        client = Instagram.client(access_token: provider.secret)
        p "client ======> #{client}"
        @feed = client.user_recent_media.first(amount_of_posts)
        p "client ======> #{@feed}"
      else
        client = Instagram.client(access_token: provider.secret)
        p "client ======> #{client}"
        @feed = client.user_recent_media.first(amount_of_posts)
        p "client ======> #{@feed}"
      end

    rescue Instagram::BadRequest => e
      p '--------------------' * 5
      p e.message

=begin
      if e.message =~ /access_token provided is invalid/
        provider.destroy
        Message.by_user(user.id)
               .by_social('instagram')
               .by_post_code(nil).by_network(nil)
               .destroy_all
      end
=end
      false
    end
  end

  def save_messages
    if feed.present?
      feed.each do |post|
        begin
          caption = post.caption.text
          created_time = post.caption.created_time
        rescue
          caption = post.caption
          created_time = post.created_time
        end
        old_message = Message.find_by(
          user_id: user.id,
          social: 'instagram',
          social_id: post.id.to_s,
          created_at: DateTime.strptime(created_time, '%s'),
          messageable: nil,
          post_code: nil,
          undercover: false
        )
        next if old_message.present?
        new_message = Message.create(text: caption,
                                     user_id: user.id,
                                     social: 'instagram',
                                     social_id: post.id.to_s,
                                     created_at: DateTime.strptime(created_time, '%s'),
                                     undercover: false,
                                     post_permalink: post.link)
        if post.carousel_media.present?
          post.carousel_media.each do |media|
            if media.type == 'image'
              new_message.images << Image.create(url: media.images.standard_resolution.url)
            elsif media.type == 'video'
              new_message.videos << Video.create(url: media.videos.standard_resolution.url)
            end
          end
        else
          if post.type == 'image'
            new_message.images << Image.create(url: post.images.standard_resolution.url)
          elsif post.type == 'video'
            new_message.videos << Video.create(url: post.videos.standard_resolution.url, thumbnail_url: post.images.standard_resolution.url)
          end
        end
      end
    end
  end
end
