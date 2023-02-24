module V1
  module Admin
    class AuctionsController < ApiController
      before_action :set_auction, only: [:show, :update, :destroy]

      def index
        @auctions = Auction.kept.includes(:company, :attachments, :categories, :categoricals)
        render json: @auctions, include_lots: false, current_user: @current_user
      end

      def show
        render json: @auction, include_lots: true, current_user: @current_user
      end

      def create
        @auction = Auction.new(auction_params)

        if @auction.save
          render json: @auction, serializer: AuctionSerializer, current_user: @current_user, status: :created, location: @auction
        else
          render json: @auction.errors, status: :unprocessable_entity
        end
      end

      def update
        if @auction.update(auction_params)
          render json: @auction, serializer: AuctionSerializer, current_user: @current_user
        else
          render json: @auction.errors, status: :unprocessable_entity
        end
      end

      def destroy
        return render_unauthorized('Closed Auction cannot be deleted.') if @auction.closed?
        @auction.discard
      end

      def autocomplete
        render json: { results: Auction.search(params[:query], {
            fields: ['name_translations.en', 'name_translations.nl', 'name_translations.fr'],
            match: :word_start,
            limit: 10,
            load: false,
            misspellings: { below: 5 }
          })
        }
      end

      private
        def set_auction
          @auction = Auction.friendly.find(params[:id])
        end

        def auction_params
          params.fetch(:auction).permit(:name, :community_id, :company_id, :is_private, :is_inactive, :inactive_reason, :visible_date, :start_date, :end_date, :hide_date, name_translations: {}, description_translations: {}, extra_translations: {}, attachments_attributes: [:id, :photo, :position, :tour_code, :_destroy], category_ids: [])
        end

    end
  end
end
