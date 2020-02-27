class Api::V1::CronsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def todays_event_notifications
    # Get today's somvo events
    # Send notification to somvo members
    # Mark notification status as sent
    today = Date.today
    somvos = Message.by_somvo_only
                    .where(:start_date => today.beginning_of_day..today.end_of_day)
                    .where(:notification_status => 0)

    # loop over somvos and send notification to members
    somvos.each do |somvo|
        p "sovmo #id = #{somvo.id} ********************  Start *****************************"
        somvo.update(notification_status: 1)

        # skip if community ids not set
        next if somvo.extra.blank?

        owner = User.find(somvo.user_id)
        extra = JSON.parse(somvo.extra)
        community_ids = extra['community_ids'].uniq

        next if community_ids.blank?

        communities = Message.by_ids(community_ids)
                             .by_communities_only
                             .by_not_deleted

        communities.each do |community|
          # get members
          members = community.room.rooms_users

          # get registration ids of members
          member_ids = members.map(&:user_id)

          user_ids = member_ids.uniq.compact
          users = User.where(id: user_ids)

          # send notifications
          user_registration_ids = users.map(&:registration_id).compact

          notification_title = owner.name
          notification_body = somvo.title #todo: on day of event nofication format : "Dinner at 7:00pm"

          if user_registration_ids.length > 0
            notifications_result = Notifications::Push.new(
                nil,
                notification_title,
                notification_body,
                user_registration_ids,
                params
            ).perform
          end
        end
    end

    render json: {
        message: somvos
    }
  end

end
