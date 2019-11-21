class Notifications::Push

  def initialize(user, title, description, receivers, child_message)
    @user = user
    @title = title
    @description = description
    @receivers = receivers
    @child_message = child_message
  end

  def perform
    #android_devices = user.user_devices.android
    #ios_devices = user.user_devices.ios
    #notify_android(android_devices) if android_devices.present?
    #notify_ios(ios_devices) if ios_devices.present?

    #android_devices = ['fInuZBisX3A:APA91bETr36MCaDXq9fuafeNYxHj2mpiOwngj7HpE4HGNyrTuQ3pKVVAOTMDLb4AMwn0Ghre44OVj_NK29K9oalnbKnryQhf7dmDHUWMHyfv_RaTsvMgavO20-TbMrp1Aktl-QjtXelZ', 'cNm6smx1KAU:APA91bFgqBVKpnDV-oPJv2kXvZe3eKSrw14Kek4OJngaAYeoPTrz03AE8E9vxU0kyxfbfsab2IfFSxX2e1gb1KJKZOfIjzznY-hPUViX6WAbHiKKvJIYTUy8d7QjbuU5uPJlANcCpFgW']
    android_devices = receivers

    notify_android(android_devices)
  end

  private
  attr_reader :title, :description, :receivers, :child_message

  def notify_android(devices, collapse_key = nil)
    require 'fcm'
    fcm = FCM.new(ENV['FCM_SERVER_KEY'])
    
    #registration_ids = devices.map(&:registration_id)
    registration_ids = devices

    options = {
      notification: {
        title: title,
        body: description
      },
      data: {
         title: title,
         body: description,
         child_message: child_message,
         'content-available': 1
      },
    }


    # options = {
    #   data: {
    #      title: title,
    #      body: description,
    #      notId: child_message[:id],
    #      child_message: child_message,
    #      'content-available': 1
    #   },
    # }

    
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
