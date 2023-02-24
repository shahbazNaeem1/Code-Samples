module VAT
  module CalculateSale
    class MarginSale < Sale
      attr_reader :bid, :lot, :auction, :user
      attr_accessor :response_hash

      DEFAULT_LUXURY_PERCENTAGE = 0.21
      DEFAULT_NON_LUXURY_PERCENTAGE = 0.06
      ZERO_PERCENTAGE = 0.00

      def initialize(bid, lot, auction, user)
        @bid = bid
        @lot = lot
        @auction = auction
        @user = user

        @response_hash = get_response_hash
        response_hash[:type_of_sale] = 'margin_sale'
      end

      def calculate_vat
        response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
        response_hash[:vat_margin_sale] = true

        if user.in_eu?
          handle_buyer_in_eu
        elsif user_in_country_change_of_goods?
          handle_buyer_in_country_change_of_goods
        else
          handle_buyer_in_non_eu
        end

        response_hash
      end

      private
        def user_in_country_change_of_goods?
          user.address[:country] == lot.release_location[:country]
        end

        def handle_buyer_in_eu
          if user.private?
            response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE

            if lot.in_country?('BEL')
              response_hash[:goods_invoiced_by] = :fokepi_be
              response_hash[:margin_invoiced_by] = :vavato_be
            elsif lot.in_country?('NLD')
              response_hash[:goods_invoiced_by] = :fokepi_nl
              response_hash[:margin_invoiced_by] = :vavato_nl
            end
          else
            if user_in_country_change_of_goods?
              handle_buyer_in_country_change_of_goods
            else
              response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
              response_hash[:goods_invoiced_by] = :fokepi_be
              response_hash[:margin_invoiced_by] = :vavato_be
              response_hash[:vat_reversed_charge] = true
            end
          end
        end

        def handle_buyer_in_country_change_of_goods
          unless user.private?
            if lot.in_country?('BEL')
              response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              response_hash[:goods_invoiced_by] = :fokepi_be
              response_hash[:margin_invoiced_by] = :vavato_be
            elsif lot.in_country?('NLD')
              response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
              response_hash[:goods_invoiced_by] = :fokepi_be # Exception invoiced from Belgian VAT number
              response_hash[:margin_invoiced_by] = :vavato_be # Exception invoiced from Belgian VAT number
              response_hash[:vat_reversed_charge] = true
            end
          end
        end

        def handle_buyer_in_non_eu
          if user.private?
            response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE

            if lot.in_country?('BEL')
              response_hash[:goods_invoiced_by] = :fokepi_be
              response_hash[:margin_invoiced_by] = :vavato_be
            elsif lot.in_country?('NLD')
              response_hash[:goods_invoiced_by] = :fokepi_nl
              response_hash[:margin_invoiced_by] = :vavato_nl
            end
          else
            if user_in_country_change_of_goods?
              handle_buyer_in_country_change_of_goods
            else
              response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
              response_hash[:goods_invoiced_by] = :fokepi_be
              response_hash[:margin_invoiced_by] = :vavato_be
              response_hash[:vat_export] = true
            end
          end
        end
    end
  end
end
