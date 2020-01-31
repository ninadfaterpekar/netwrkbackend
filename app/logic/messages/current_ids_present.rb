class Messages::CurrentIdsPresent
  include Service

  def initialize(args)
    @current_ids = args[:current_ids]
    @undercover_messages = args[:undercover_messages]
    @with_network = args[:with_network]
    @user = args[:user]
    @is_undercover = args[:is_undercover]
  end

  def perform
    logic
  end

  def perform_nearby
    logic_nearby
  end
  private

  attr_reader :undercover_messages, :user, :current_ids, :with_network, :is_undercover

  def logic
    if current_ids.present?
      quered_ids =
        undercover_messages.present? ? undercover_messages.pluck(:id) : []
      if  current_ids.split(',').map(&:to_i) ==
          (current_ids.split(',').map(&:to_i) && quered_ids)
        _ids_to_remove = []
        _undercover_messages = []
      else
        new_ids = quered_ids - current_ids.split(',').map(&:to_i)
        @undercover_messages = undercover_messages.by_ids(new_ids)
        create_locked_messages if with_network
        undercover_messages.each { |message| message.current_user = user }

        if is_undercover == 'true'
          undercover_messages.as_json(
            methods: %i[
              avatar_url image_urls video_urls like_by_user legendary_by_user user is_synced
              text_with_links post_url expire_at has_expired locked_by_user is_followed is_connected line_locked_by_user
              conversation_status users_count room_id  line_message_type
            ],
            include: [
              :custom_line,
              :non_custom_lines,
              room: {
                only: [
                  :id,
                  :message_id,
                  :users_count,
                ],
                include: [
                  rooms_users: {
                    methods: [
                      :user
                    ],
                    only: [
                      :id,
                      :room_id,
                      :user_id,
                      :read,
                      :unread_count
                    ]
                  }
                ]
              }
            ]
          )
        else
          undercover_messages.as_json(
            methods: %i[
              avatar_url image_urls video_urls like_by_user legendary_by_user user is_synced
              text_with_links post_url expire_at has_expired is_connected locked_by_user is_followed line_locked_by_user
              conversation_status users_count room_id  line_message_type
            ],
            include: [
              :custom_line,
              :non_custom_lines,
              room: {
                only: [
                  :id,
                  :message_id,
                  :users_count,
                ],
                include: [
                  rooms_users: {
                    methods: [
                      :user
                    ],
                    only: [
                      :id,
                      :room_id,
                      :user_id,
                      :read,
                      :unread_count
                    ]
                  }
                ]
              }
            ]
          )
        end
      end
    else
      ids_to_remove = []
      create_locked_messages if with_network
      undercover_messages.each { |message| message.current_user = user }

      if is_undercover == 'true'
        @undercover_messages = undercover_messages.as_json(
          methods: %i[
            avatar_url image_urls video_urls like_by_user legendary_by_user user is_synced
            text_with_links post_url expire_at has_expired locked_by_user is_followed is_connected line_locked_by_user
            conversation_status users_count room_id  line_message_type
          ],
          include: [
            :non_custom_lines,
            room: {
              only: [
                :id,
                :message_id,
                :users_count,
              ],
              include: [
                rooms_users: {
                  methods: [
                    :user
                  ],
                  only: [
                    :id,
                    :room_id,
                    :user_id,
                    :read,
                    :unread_count
                  ]
                }
              ]
            }
          ]
        )
      else
        @undercover_messages = undercover_messages.as_json(
          methods: %i[
            avatar_url image_urls video_urls like_by_user legendary_by_user user is_synced
            text_with_links post_url expire_at has_expired is_connected locked_by_user is_followed line_locked_by_user
            conversation_status users_count room_id  line_message_type
          ],
          include: [
            :non_custom_lines,
            room: {
              only: [
                :id,
                :message_id,
                :users_count,
              ],
              include: [
                rooms_users: {
                  methods: [
                    :user
                  ],
                  only: [
                    :id,
                    :room_id,
                    :user_id,
                    :read,
                    :unread_count
                  ]
                }
              ]
            }
          ]
        )
      end

      [undercover_messages, ids_to_remove]
    end
  end

def logic_nearby
    if current_ids.present?
      quered_ids =
        undercover_messages.present? ? undercover_messages.pluck(:id) : []
      if  current_ids.split(',').map(&:to_i) ==
          (current_ids.split(',').map(&:to_i) && quered_ids)
        _ids_to_remove = []
        _undercover_messages = []
      else
        new_ids = quered_ids - current_ids.split(',').map(&:to_i)
        @undercover_messages = undercover_messages.by_ids(new_ids)
        create_locked_messages if with_network
        undercover_messages.each { |message| 
          message.current_user = user 
        }
        undercover_messages.as_json(
          methods: %i[
            avatar_url user
            expire_at has_expired is_followed locked_by_user
          ],
          include: [
              :non_custom_lines
          ]
        )
      end
    else
      ids_to_remove = []
      create_locked_messages if with_network
      undercover_messages.each { |message| 
        message.current_user = user
      }
      @undercover_messages = undercover_messages.as_json(
        methods: %i[
          avatar_url user
          expire_at has_expired is_followed locked_by_user 
        ],
        include: [
              :non_custom_lines
        ]
      )
      [undercover_messages, ids_to_remove]
    end
  end

  def create_locked_messages
    undercover_messages.locked_is(true).each do |m|
      LockedMessage.find_or_create_by(user_id: user.id, message_id: m.id)
    end
  end
end
