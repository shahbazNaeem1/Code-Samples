class User < ApplicationRecord
  include Discard::Model
  include Categorizable

  serialize :address, Hash

  enum verification_status: %w[to_be_submitted submitted verified refused]

  rolify
  has_paper_trail

  has_one :buyer_entity, -> { where(entity_class: 'BuyerEntity') }, as: :profileable
  has_one :seller_entity, -> { where(entity_class: 'SellerEntity') }, as: :profileable

  has_many :tokens
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :entities, as: :profileable
  has_many :notifications
  has_many :notification_preferences
  has_many :bids
  has_many :lots, -> { distinct }, through: :bids
  has_many :interests, through: :categoricals, source: :category # alias of categories
  has_many :user_followings, dependent: :destroy
  has_many :ratings, foreign_key: :receiver_id, class_name: 'FeedbackSubmission'
  has_many :active_following_auctions, -> {
                                            where('current_closing_date > ?', Time.now).
                                            active.
                                            order(:current_closing_date)
                                          },
                                      through: :user_followings,
                                      source: :followable, source_type: 'Auction'
  has_many :active_following_lots, -> {
                                        where('current_closing_date > ?', Time.now).
                                        order(:current_closing_date)
                                      },
                                  through: :user_followings,
                                  source: :followable, source_type: 'Lot'

  belongs_to :company, optional: true

  accepts_nested_attributes_for :attachments, allow_destroy: true, reject_if: :all_blank

  after_create :create_entities
  after_create :create_or_update_zoho_contact
  after_create :create_notification_preferences

  after_update :create_or_update_zoho_contact, if: :saved_change_to_last_name?
  after_update :handle_verification_status_change, if: :saved_change_to_verification_status?

  validates :email, uniqueness: { scope: :discarded_at }

  def in_eu?
    self.address[:country].in? EU_COUNTRIES
  end

  def private?
    self.company.blank?
  end

  def entity_type
    private? && 'private' || nil
  end

  def name
    [self.first_name, self.last_name].join(' ')
  end

  def company_attributes=(values)
    if values[:_destroy].present?
      self.company = nil
    else
      return if values[:vat_number].blank?

      c = Company.where(vat_number: values[:vat_number]).first_or_create(name: values[:name])
      self.company = c
    end
  end

  def self.defaulters
    user_ids = BuyerEntity.joins(:payment_requests).where(invoices: {status: PaymentRequest.statuses['overdue']}).pluck(:profileable_id)
    User.where(id: user_ids)
  end

  def actor
      if self.company != nil
        self.company.buyer_entity
      else
        self.buyer_entity
      end
  end

  def can_upload_attachments
    errors.add(:attachments, 'Your request for verification is already in progress.') if attachments_changed? && !to_be_submitted?
  end

  def lots_details
    bid_ids = self.bids.pluck(:id)

    {
      following: ActiveModel::SerializableResource.new(
        self.active_following_lots,
        each_serializer: V1::LotSerializer,
        scope: { include_current_bid: true, include_auction: true, current_user: Current.user }
      ).serializable_hash,
      bids_on: ActiveModel::SerializableResource.new(
        self.lots.open,
        each_serializer: V1::LotSerializer,
        scope: { include_current_bid: true, include_auction: true, current_user: Current.user }
      ).serializable_hash,
      won: ActiveModel::SerializableResource.new(
        self.lots.closed.where(current_bid_id: bid_ids),
        each_serializer: V1::LotSerializer,
        scope: { include_current_bid: true, include_auction: true, current_user: Current.user }
      ).serializable_hash,
      lost: ActiveModel::SerializableResource.new(
        self.lots.closed.where.not(current_bid_id: bid_ids),
        each_serializer: V1::LotSerializer,
        scope: { include_current_bid: true, include_auction: true, current_user: Current.user }
      ).serializable_hash,
      negotation: ActiveModel::SerializableResource.new(
        self.lots.where(assign_status: ['wait_for_buyer','wait_for_seller']),
        each_serializer: V1::LotSerializer,
        scope: { include_current_bid: true, include_auction: true, current_user: Current.user }
      ).serializable_hash,
    }
  end

  def dashboard_counts
    {
      my_lots: self.notifications.unseen.regarding_lots.count,
      my_purchase_invoices: self.buyer_entity.payment_requests.not_paid.count,
      feedbacks: pending_feedbacks_count,
      my_sales: self.seller_entity.lots.open.count,
      my_sales_invoices: 0,
      my_account: account_verified? && 0 || 1
    }
  end

  private
    def attachments_changed?
      attachments.collect(&:changed?).any?
    end

  def create_entities
    self.create_buyer_entity(profileable_name: self.name)
    self.create_seller_entity(profileable_name: self.name)
  end

  def create_or_update_zoho_contact
    unless self.entities.first.zoho_contact_id.present?
      CreateZohoContact.perform_later(self)
    else
      UpdateZohoContact.perform_later(self)
    end
  end

  def create_notification_preferences
    NotificationEvent.pluck(:id).each do |notification_event_id|
      self.notification_preferences.find_or_create_by(notification_event_id: notification_event_id)
    end
  end

  def pending_feedbacks_count
    lot_ids = Lot.joins(:current_bid).closed.where(bids: { user_id: self.id }).pluck(:id).uniq

    feedback_submissions_count = FeedbackSubmission.where(lot_id: lot_ids, user_id: self.id).count

    lot_ids.length - feedback_submissions_count
  end

  def account_verified?
    self.verification_status == 'verified' || self.verification_status == 'submitted'
  end

  def handle_verification_status_change
    if self.refused?
      CreateNotificationsJob.perform_later(
        group_name: 'user_profile',
        entity: 'User',
        action: 'verification_refused',
        user: self
      )

      self.attachments.delete_all
      self.update_columns(verification_status: 'to_be_submitted')
    elsif self.verified?
      CreateNotificationsJob.perform_later(
        group_name: 'user_profile',
        entity: 'User',
        action: 'verification_approved',
        user: self
      )
    elsif self.to_be_submitted?
      self.submitted! if self.attachments.present?
    end
  end
end
