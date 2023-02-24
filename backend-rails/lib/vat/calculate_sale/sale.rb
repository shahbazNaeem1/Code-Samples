module VAT
  module CalculateSale
    class Sale
      protected
        def get_response_hash
          {
            goods_vat_percentage: nil, # (%)
            goods_invoiced_by: nil, # ("vavato_be", "vavato_nl", "fokepi_be", "fokepi_nl", "seller")
            margin_vat_percentage: nil, # (%)
            margin_invoiced_by: nil, # ("vavato_be", "vavato_nl") # Included in Margin Sale only? Please confirm.
            vat_margin_sale: false, # (y/n)
            vat_reversed_charge: false, # (y/n)
            vat_export: false, # (y/n)
            type_of_sale: nil
          }
        end
    end
  end
end
