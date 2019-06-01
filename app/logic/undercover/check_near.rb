class Undercover::CheckNear
  include Service

  def initialize(post_code, current_lng, current_lat, user, messages)
    @post_code = post_code
    @current_lng = current_lng
    @current_lat = current_lat
    @user = user
    @nearby_messages = messages
  end

  def perform
    messages_in_radius
  end

  private
  attr_reader :post_code, :user, :current_lng, :current_lat, :nearby_messages

  def messages_in_radius

    messages_in_radius = []

    if nearby_messages.empty?
      messages = Message.undercover_is(true).with_users
    else
      messages = nearby_messages
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

      # next unless (message.lat.to_s[0..3] == current_lat.to_s[0..3]) ||
      #             (message.lng.to_s[0..3] == current_lng.to_s[0..3])

      distance = Geocoder::Calculations.distance_between(
        [current_lng, current_lat], [message.lng, message.lat]
      )
      message.current_user = user
      if in_radius?(miles_to_yards(distance), 26400) && !message.deleted_by_user?
        messages_in_radius << message
      end
    end
    messages_in_radius
  end

  def miles_to_yards(miles)
    miles * 1760
  end

  def in_radius?(yards, limitInYards)
    #26400 yards = 15 miles
    yards <= limitInYards
  end

end
