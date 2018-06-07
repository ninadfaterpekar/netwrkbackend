class Autocasting::FetchFromSocials
  include Service

  def initialize(args)
    @user = args[:user]
  end

  def perform
    Facebook::FeedFetch.new(user, 15).perform
    Twitter::FeedFetch.new(user, 15).perform
    Instagram::FeedFetch.new(user, 15).perform
    user.networks.each do |network|
      socials = ['facebook', 'twitter', 'instagram']
      socials.each do |social|
        messages = Message.by_user(user.id)
                          .by_social(social)
                          .by_post_code(nil).by_network(nil).order(created_at: :desc)
        unless network.messages.by_user(user.id).by_social(social).present?
          add_message_to_area(messages.first, network) if messages.present?
          next
        end
        messages.each do |message|
          unless network.messages.by_social(social).by_user(user.id).present?
            add_message_to_area(messages.first, network) if messages.present?
            break
          end
          ms = network.messages.by_social(social).by_user(user.id).find_by(social_id: message.social_id)
          if ms.present?
            break if network.messages.by_social(social).by_user(user.id).first.social_id == ms.social_id
          else
            add_message_to_area(message, network) if message.present?
          end
        end
      end
    end
  end

  private

  attr_reader :user

  def add_message_to_area(message, network)
    m = Message.create(
      text: message.text,
      user_id: message.user_id,
      social: message.social,
      social_id: message.social_id,
      created_at: Time.current,
      url: message.url,
      undercover: message.undercover,
      post_code: network.post_code,
      post_permalink: message.post_permalink,
      network_id: network.id
    )

    message.images.each do |image|
      i = Image.create(
        url: image.url,
        image: image.image,
      )
      m.images << i
    end

    message.videos.each do |video|
      v = Video.create(
        url: video.url,
        video: video.video,
        thumbnail_url: video.thumbnail_url
      )
      m.videos << v
    end
    ActionCable.server.broadcast  "messages#{network.post_code}chat",
                                  message: m.as_json(
                                    methods: %i[
                                      image_urls locked video_urls user
                                      text_with_links post_url expire_at
                                      has_expired locked_by_user
                                    ]
                                  )
  end
end
