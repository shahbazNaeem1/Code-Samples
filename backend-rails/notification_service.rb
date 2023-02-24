class NotificationService
  attr_accessor :notification, :user, :channel

  def initialize(notification)
    @notification = notification
    @user = notification.user
    @channel = ['user-', user.email].join
  end

  def send_notification!
    method_name = "handle_#{notification.group_name}"
    send(method_name) if self.class.private_method_defined?(method_name)
  end

  private
    def handle_lots_selling
      send("handle_lots_selling_#{notification.entity.downcase}")
    end

    def handle_lots_bid_on
      send("handle_lots_bid_on_#{notification.entity.downcase}")
    end

    def handle_lots_followed
      send("handle_lots_followed_#{notification.entity.downcase}")
    end

    def handle_auctions_followed
      send("handle_auctions_followed_#{notification.entity.downcase}")
    end

    def handle_user_profile
      case notification.action
        when 'verification_refused'
          title = 'Verification Status'
          description = 'Your verification gets refused.'
          send_pubnub_notification(title, description)
        when 'verification_approved'
          title = 'Verification Status'
          description = 'Your verification gets approved.'
          send_pubnub_notification(title, description)
      end
    end

    def handle_lots_selling_auction
      case notification.action
        when 'bidding_open'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
      end
    end

    def handle_lots_selling_lot
      case notification.action
        when 'new_bid'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'minimum_price_not_reached'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'assigned'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'will_not_assign'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'negotation'
          lot = notification.notifiable
          title = "#{lot.title} need to take an action."
          description = '(assign manually, ask again for a higher bid, will not assign)'

          send_pubnub_notification(title, description)
      end
    end

    def handle_lots_bid_on_bid
      case notification.action
        when 'overbid'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'deleted'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
      end
    end

    def handle_lots_bid_on_lot
      case notification.action
        when 'won'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'negotation'
          lot = notification.notifiable
          title = "#{lot.title} minimum price was not reached"
          description = 'and seller has requested for a higher bid to be place.'

          send_pubnub_notification(title, description)
      end
    end

    def handle_lots_bid_on_auction
      case notification.action
        when 'closes_in_3_hours'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
      end
    end

    def handle_lots_followed_auction
      case notification.action
        when 'bidding_open'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'closes_in_3_hours'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'bidding_closed'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
      end
    end

    def handle_auctions_followed_auction
      case notification.action
        when 'bidding_open'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
        when 'closes_in_3_hours'
          send_pubnub_notification(notification.formatted[:title], notification.formatted[:description])
      end
    end

    def send_pubnub_notification(title, description)
      message = { title: title, description: description }
      ThePubnubJob.perform_later(channel, message)
    end
end
