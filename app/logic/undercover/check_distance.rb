class Undercover::CheckDistance
  include Service

  def initialize(post_code, current_lng, current_lat, user, is_landing_page)
    @post_code = post_code
    @current_lng = current_lng
    @current_lat = current_lat
    @user = user
    @is_landing_page = is_landing_page
  end

  def perform
    messages_in_radius
  end

  private
  attr_reader :post_code, :user, :current_lng, :current_lat, :is_landing_page

  def messages_in_radius
    messages_in_radius = []
    # network = Network.find_by(post_code: post_code)
    # on landing page display own conversation + Lines (any user) if within distance
    if is_landing_page == 'true'
      messages = Message.where("((undercover = false and user_id = :user_id) or (undercover = true))", {user_id: user})
                        .where("message_type = 'CUSTOM_LOCATION'")
                        .with_users
    else
      messages = Message.where("message_type = 'CUSTOM_LOCATION'").undercover_is(true).with_users
    end

    messages.each do |message|

      # Caclulate distance between those messages only which are near to current location lat and lng
      # Skip checking distance for messages which are far from current location.
      message_lat = message.lat.to_s[0..3].to_f 
      message_lng = message.lng.to_s[0..3].to_f

      current_lat_min = (current_lat.to_s[0..3].to_f.floor - 1) 
      current_lat_max = (current_lat.to_s[0..3].to_f.floor + 1) 

      current_lng_min = (current_lng.to_s[0..3].to_f.floor - 1)
      current_lng_max = (current_lng.to_s[0..3].to_f.floor + 1)

      next unless (message_lat >= current_lat_min && message_lat <= current_lat_max) &&
                  (message_lng >= current_lng_min && message_lng <= current_lng_max)

      # next unless (message.lat.to_s[0..3] == current_lat.to_s[0..3]||
      #             (message.lng.to_s[0..3] == current_lng.to_s[0..3])

      distance = Geocoder::Calculations.distance_between(
        [current_lng, current_lat], [message.lng, message.lat]
      )
      message.current_user = user
      if in_radius?(miles_to_yards(distance)) && !message.deleted_by_user?
        messages_in_radius << message
      end
    end
    messages_in_radius
  end

  def miles_to_yards(miles)
    miles * 1760
  end

  def in_radius?(yards)
    yards <= 100
  end
end
