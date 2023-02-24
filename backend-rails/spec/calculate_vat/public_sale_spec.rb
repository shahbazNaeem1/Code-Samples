require 'rails_helper'

RSpec.describe 'Calculate VAT' do
  before do
    @buyer = User.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      mobile: Faker::PhoneNumber.cell_phone,
      phone: Faker::PhoneNumber.phone_number,
      is_blocked: false
    )

    @seller = User.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      mobile: Faker::PhoneNumber.cell_phone,
      phone: Faker::PhoneNumber.phone_number,
      is_blocked: false
    )

    @auction = Auction.new(name: Faker::Commerce.department)

    @lot = @auction.lots.new(
      title: Faker::Commerce.product_name,
      opening_bid_price: Faker::Number.decimal(2),
      buy_immediate_price: 100,
      currency: Faker::Currency.code,
      status: 0,
      seller_entity: @seller.seller_entity
    )

    @company = Company.new(name: Faker::Company.name)
  end

  describe 'PublicSale' do
    before do
      @lot.anonymous_sale = false
      @lot.margin_sale = false
      @lot.margin_car = false
    end

    describe 'Lot with MarginSale' do
      before do
        @lot.margin_sale = true
        @lot.margin_car = true
      end

      it 'Lot in BEL' do
        @lot.release_location[:country] = 'BEL'
        response_hash = @lot.calculate_vat(@buyer)

        expect(response_hash[:goods_vat_percentage]).to equal nil
        expect(response_hash[:goods_invoiced_by]).to equal nil
        expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
        expect(response_hash[:margin_invoiced_by]).to equal :vavato_be
        expect(response_hash[:vat_margin_sale]).to equal true
        expect(response_hash[:vat_reversed_charge]).to equal false
        expect(response_hash[:vat_export]).to equal false
        expect(response_hash[:type_of_sale]).to eq('public_sale')
      end

      it 'Lot in NLD' do
        @lot.release_location[:country] = 'NLD'
        response_hash = @lot.calculate_vat(@buyer)

        expect(response_hash[:goods_vat_percentage]).to equal nil
        expect(response_hash[:goods_invoiced_by]).to equal nil
        expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
        expect(response_hash[:margin_invoiced_by]).to equal :vavato_nl
        expect(response_hash[:vat_margin_sale]).to equal true
        expect(response_hash[:vat_reversed_charge]).to equal false
        expect(response_hash[:vat_export]).to equal false
        expect(response_hash[:type_of_sale]).to eq('public_sale')
      end
    end

    describe 'Lot without MarginSale' do
      before do
        @lot.margin_sale = false
        @lot.margin_car = false
      end

      describe 'Buyer in EU' do
        before do
          @buyer.address[:country] = EU_COUNTRIES.sample
        end

        context 'Private' do
          before do
            @buyer.company = nil
          end

          it 'Lot in BEL' do
            @lot.release_location[:country] = 'BEL'
            response_hash = @lot.calculate_vat(@buyer)

            expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
            expect(response_hash[:goods_invoiced_by]).to equal :seller
            expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::DEFAULT_LUXURY_PERCENTAGE
            expect(response_hash[:margin_invoiced_by]).to equal :vavato_be
            expect(response_hash[:vat_margin_sale]).to equal false
            expect(response_hash[:vat_reversed_charge]).to equal false
            expect(response_hash[:vat_export]).to equal false
            expect(response_hash[:type_of_sale]).to eq('public_sale')
          end

          it 'Lot in NLD' do
            @lot.release_location[:country] = 'NLD'
            response_hash = @lot.calculate_vat(@buyer)

            expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
            expect(response_hash[:goods_invoiced_by]).to equal :seller
            expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::DEFAULT_LUXURY_PERCENTAGE
            expect(response_hash[:margin_invoiced_by]).to equal :vavato_nl
            expect(response_hash[:vat_margin_sale]).to equal false
            expect(response_hash[:vat_reversed_charge]).to equal false
            expect(response_hash[:vat_export]).to equal false
            expect(response_hash[:type_of_sale]).to eq('public_sale')
          end
        end

        context 'Not Private' do
          before do
            @buyer.company = @company
          end

          context 'In country change of goods' do
            it 'Lot in BEL' do
              @lot.release_location[:country] = 'BEL'
              @buyer.address[:country] = @lot.release_location[:country]
              response_hash = @lot.calculate_vat(@buyer)

              expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
              expect(response_hash[:goods_invoiced_by]).to equal :seller
              expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::DEFAULT_LUXURY_PERCENTAGE
              expect(response_hash[:margin_invoiced_by]).to equal :vavato_be
              expect(response_hash[:vat_margin_sale]).to equal false
              expect(response_hash[:vat_reversed_charge]).to equal false
              expect(response_hash[:vat_export]).to equal false
              expect(response_hash[:type_of_sale]).to eq('public_sale')
            end

            it 'Lot in NLD' do
              @lot.release_location[:country] = 'NLD'
              @buyer.address[:country] = @lot.release_location[:country]
              response_hash = @lot.calculate_vat(@buyer)

              expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
              expect(response_hash[:goods_invoiced_by]).to equal :seller
              expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
              expect(response_hash[:margin_invoiced_by]).to equal :vavato_be
              expect(response_hash[:vat_margin_sale]).to equal false
              expect(response_hash[:vat_reversed_charge]).to equal true
              expect(response_hash[:vat_export]).to equal false
              expect(response_hash[:type_of_sale]).to eq('public_sale')
            end
          end

          it 'Not in country change of goods' do
            @lot.release_location[:country] = 'NLD'
            @buyer.address[:country] = 'GER'
            response_hash = @lot.calculate_vat(@buyer)

            expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
            expect(response_hash[:goods_invoiced_by]).to equal :seller
            expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
            expect(response_hash[:margin_invoiced_by]).to equal :vavato_be
            expect(response_hash[:vat_margin_sale]).to equal false
            expect(response_hash[:vat_reversed_charge]).to equal true
            expect(response_hash[:vat_export]).to equal false
            expect(response_hash[:type_of_sale]).to eq('public_sale')
          end
        end
      end

      describe 'Buyer not in EU' do
        context 'Private' do
          before do
            @buyer.company = nil
          end

          it 'Lot in BEL' do
            @lot.release_location[:country] = 'BEL'
            @buyer.address[:country] = @lot.release_location[:country]
            response_hash = @lot.calculate_vat(@buyer)

            expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
            expect(response_hash[:goods_invoiced_by]).to equal :seller
            expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::DEFAULT_LUXURY_PERCENTAGE
            expect(response_hash[:margin_invoiced_by]).to equal :vavato_be
            expect(response_hash[:vat_margin_sale]).to equal false
            expect(response_hash[:vat_reversed_charge]).to equal false
            expect(response_hash[:vat_export]).to equal false
            expect(response_hash[:type_of_sale]).to eq('public_sale')
          end

          it 'Lot in NLD' do
            @lot.release_location[:country] = 'NLD'
            @buyer.address[:country] = @lot.release_location[:country]
            response_hash = @lot.calculate_vat(@buyer)

            expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
            expect(response_hash[:goods_invoiced_by]).to equal :seller
            expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::DEFAULT_LUXURY_PERCENTAGE
            expect(response_hash[:margin_invoiced_by]).to equal :vavato_nl
            expect(response_hash[:vat_margin_sale]).to equal false
            expect(response_hash[:vat_reversed_charge]).to equal false
            expect(response_hash[:vat_export]).to equal false
            expect(response_hash[:type_of_sale]).to eq('public_sale')
          end
        end

        it 'Not Private' do
          @buyer.company = @company
          @lot.release_location[:country] = 'PAK'
          @buyer.address[:country] = 'IND'
          response_hash = @lot.calculate_vat(@buyer)

          expect(response_hash[:goods_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
          expect(response_hash[:goods_invoiced_by]).to equal :seller
          expect(response_hash[:margin_vat_percentage]).to equal VAT::CalculateSale::PublicSale::ZERO_PERCENTAGE
          expect(response_hash[:margin_invoiced_by]).to equal :vavato_be
          expect(response_hash[:vat_margin_sale]).to equal false
          expect(response_hash[:vat_reversed_charge]).to equal false
          expect(response_hash[:vat_export]).to equal true
          expect(response_hash[:type_of_sale]).to eq('public_sale')
        end
      end
    end
  end
end
