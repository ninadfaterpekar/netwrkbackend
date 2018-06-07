#app/assets/javascripts/channels/room.coffee
App.room = App.cable.subscriptions.create "ChatChannel",
  connected: -> # Called when the subscription is ready for use on the server
  disconnected: -> # Called when the subscription has been terminated by the server
  received: (data) -> # Called when there's incoming data on the websocket for this channel
    console.log(data)

  speak: (mess) ->
    @perform 'speak', message: mess

$(document).on 'keypress', '[data-behavior~="chat_speaker"]', (event) ->
  console.log('clicked')
  console.log(event.target.value)
  if event.keyCode is 13 # return/enter = send
    event.preventDefault()
    event.stopPropagation()
    App.room.speak event.target.value
    event.target.value = ''
