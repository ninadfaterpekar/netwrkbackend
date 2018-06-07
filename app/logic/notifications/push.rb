class Notifications::Push

  def initialize(user, title, description)
    @user = user
    @title = title
    @description = description
  end

  def self.perform
    android_devices = user.user_devices.android
    ios_devices = user.user_devices.ios
    notify_android(android_devices) if android_devices.present?
    notify_ios(ios_devices) if ios_devices.present?
  end

  private

  def notify_android(devices, collapse_key = nil)
    require 'fcm'
    fcm = FCM.new(ENV['FCM_SERVER_KEY'])
    registration_ids = devices.map(&:registration_id)
    options = {
      notification: {
        title: title,
        body: description
      }
    }
    fcm.send(registration_ids, options)
  end

  def notify_ios(devices)
    require 'houston'
    apn = Houston::Client.production
    # apn = Houston::Client.development
    apn.certificate = File.read('push_production.pem')
    devices.each do |device|
      notification = Houston::Notification.new(device: device.registration_id)
      notification.alert = {title: title, body: description}
      notification.sound = 'sosumi.aiff'
      apn.push(notification)
    end
  end
end
