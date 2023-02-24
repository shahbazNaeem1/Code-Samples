module VAT
  module CalculateSale
    class PrivateSale < Sale
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
        response_hash[:type_of_sale] = 'private_sale'
      end

      def calculate_vat
        if user.in_eu?
          handle_user_in_eu
        elsif user_in_country_change_of_goods?
          handle_user_in_country_change_of_goods
        else
          handle_user_in_non_eu
        end

        response_hash
      end

      private
        def export_documents_received?
          # bid.assignment.export_documents_received
          false
        end

        def user_in_country_change_of_goods?
          user.address[:country] == lot.release_location[:country]
        end

        def export_declaration_received?
          # invoice export_declaration_received -> true
          false
        end

        def handle_user_in_eu
          if user.private?
            if lot.in_country?('BEL')
              response_hash[:goods_invoiced_by] = :vavato_be
              response_hash[:margin_invoiced_by] = :vavato_be

              if lot.luxury?
                response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              else
                response_hash[:goods_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
                response_hash[:margin_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
              end
            elsif lot.in_country?('NLD')
              response_hash[:goods_invoiced_by] = :vavato_nl
              response_hash[:margin_invoiced_by] = :vavato_nl
              response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
            end
          else
            if user_in_country_change_of_goods?
              handle_user_in_country_change_of_goods
            elsif lot.in_country?('BEL')
              response_hash[:goods_invoiced_by] = :vavato_be
              response_hash[:margin_invoiced_by] = :vavato_be

              if export_declaration_received?
                response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:vat_reversed_charge] = true
              else
                if lot.luxury?
                  response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                  response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                else
                  response_hash[:goods_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
                  response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                end
              end
            elsif lot.in_country?('NLD')
              response_hash[:goods_invoiced_by] = :vavato_nl
              response_hash[:margin_invoiced_by] = :vavato_nl

              if export_declaration_received?
                response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:vat_reversed_charge] = true
              else
                response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              end
            end
          end
        end

        def handle_user_in_country_change_of_goods
          unless user.private?
            if lot.in_country?('BEL')
              response_hash[:goods_invoiced_by] = :vavato_be
              response_hash[:margin_invoiced_by] = :vavato_be

              if lot.luxury?
                response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              else
                response_hash[:goods_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
                response_hash[:margin_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
              end
            elsif lot.in_country?('NLD')
              response_hash[:goods_invoiced_by] = :vavato_nl
              response_hash[:margin_invoiced_by] = :vavato_nl
              response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
            else
              response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
              response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
              response_hash[:vat_reversed_charge] = true
            end
          end
        end

        def handle_user_in_non_eu
          if user.private?
            if lot.in_country?('BEL')
              response_hash[:goods_invoiced_by] = :vavato_be
              response_hash[:margin_invoiced_by] = :vavato_be

              if export_documents_received?
                response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:vat_export] = true
              else
                if lot.luxury?
                  response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                  response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                else
                  response_hash[:goods_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
                  response_hash[:margin_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
                end
              end
            elsif lot.in_country?('NLD')
              response_hash[:goods_invoiced_by] = :vavato_nl
              response_hash[:margin_invoiced_by] = :vavato_nl

              if export_documents_received?
                response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:vat_export] = true
              else
                response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              end
            end
          else
            if user_in_country_change_of_goods?
              handle_user_in_country_change_of_goods
            elsif lot.in_country?('BEL')
              response_hash[:goods_invoiced_by] = :vavato_be
              response_hash[:margin_invoiced_by] = :vavato_be

              if export_documents_received?
                response_hash[:vat_export] = true
                response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
              else
                if lot.luxury?
                  response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                  response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                else
                  response_hash[:goods_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
                  response_hash[:margin_vat_percentage] = DEFAULT_NON_LUXURY_PERCENTAGE
                end
              end
            elsif lot.in_country?('NLD')
              response_hash[:goods_invoiced_by] = :vavato_nl
              response_hash[:margin_invoiced_by] = :vavato_nl

              if export_documents_received?
                response_hash[:vat_export] = true
                response_hash[:goods_vat_percentage] = ZERO_PERCENTAGE
                response_hash[:margin_vat_percentage] = ZERO_PERCENTAGE
              else
                response_hash[:goods_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
                response_hash[:margin_vat_percentage] = DEFAULT_LUXURY_PERCENTAGE
              end
            end
          end
        end
    end
  end
end
