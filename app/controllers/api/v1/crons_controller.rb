class Api::V1::CronsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Send notification on the day of event to members of communities on which somvo is shared
  # This cron must run on each day at 12:01 AM.
  # Reminder: "Dinner at Nashik at 7:00PM?"
  # cron : 1 0 * * *
  def todays_event_notifications
    # Get today's somvo events
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
        place_name = extra["place_name"] || somvo.place_name
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
          # notification_body = somvo.title #todo: on day of event nofication format : "Dinner at 7:00pm"

          week_date = somvo.start_date
          notification_body = extra["activity"] || 'Hang out' << ' at ' <<  place_name.to_s << ' ' << week_date.strftime("%k:%M %p")

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

  # This cron must run every day at the end of the day of event
  # Ideal Time to run cron: 23:55 PM of every day
  # cron entry: 55 23 * * *
  def reset_weekly_somvos
    current_time = Time.now.utc # as all dates must store in UTC format in

    # Fetch expired somvos which are expired and 24 hours left of expiration
    somvos = Message.by_somvo_only
                 .where(:weekly_status => 1)
                 .by_not_deleted
                 .where("start_date <= :current_time", {current_time: current_time - 24.hours})

    # loop over somvos and set start date to next week, update title with next date
    # Flush room users for somvo.
    somvos.each do |somvo|
      p "******************** sovmo #id = #{somvo.id} *****************************"
      next if somvo.extra.blank?
      extra = JSON.parse(somvo.extra)
      place_name = extra["place_name"] || somvo.place_name

      next_week_date = somvo.start_date + 1.week
      title = extra["activity"] || 'Hang out' << ' at ' <<  place_name.to_s << ' ' << next_week_date.strftime("%a, %b %d, %Y %k:%M %p")

      # Remove all joined members from somvo. But keep owner of somvo itself. So other members must do again accept request to join again
      members = somvo.room.rooms_users.where.not(user_id: somvo.user_id).destroy_all
      somvo.update(start_date: next_week_date, title: title)
    end

    render json: {
        message: somvos
    }
  end

  # Remove inactive somvo
  # 1. Example
  # I create somvo
  # A. No one says I can, deletes completely after a day.
  # I can’t and no activity both delete. KEY: activity is someone saying they are in
  # cron : 1 0 * * *
  def remove_inactive_somvo
    # get inactive somvo
    # inactive : Somvo having rooms_users count <= 1 (Owner is default user of somvo)
    # and having created_at date past 1 or more days
    # Ignore the weekly recurring somvos

    somvos = Message.joins(:room)
                    .by_somvo_only
                    .by_not_deleted
                    .where.not(:weekly_status => 1)
                    .where("rooms.users_count <= 1")
                    .where("(message_type = 'LOCAL_MESSAGE' AND (messages.updated_at < :local_message_expiry_date and expire_date < :current_date))",
                    {
                        current_date: DateTime.now,
                        local_message_expiry_date: DateTime.now - 1.days
                    })

    # Delete all somvo and its request and its messages
    somvos.each do |somvo|
      if somvo.extra.blank?
        extra = {"delete_reason": 'NO_ACTIVITY', "deleted_on": DateTime.now}
      else
        extra = JSON.parse(somvo.extra)
        extra["delete_reason"] = 'NO_ACTIVITY'
        extra["deleted_on"] = DateTime.now
      end
      # Delete somvo with reason
      somvoItem = somvo.update(deleted: true, extra: extra.to_json)

      # Remove somvo messages and request
      messages = somvo.conversation_line_messages.update_all(deleted: true)
    end

    render json: {
        message: somvos
    }
  end
end
