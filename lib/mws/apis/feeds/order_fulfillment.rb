module Mws::Apis::Feeds
  class OrderFulfillment

    attr_accessor :amazon_order_id, :merchant_order_id,
                  :merchant_fulfillment_id, :fulfillment_date,
                  :carrier, :shipping_method,
                  :tracking_number, :items

    def initialize(amazon_order_id, options, items)
      @amazon_order_id = amazon_order_id
      @merchant_order_id = options[:merchant_order_id]
      @merchant_fulfillment_id = options[:merchant_fulfillment_id]
      @fulfillment_date = options[:fulfillment_date]
      @fulfillment_carrier_code = options[:carrier]
      @fulfillment_shipping_method = options[:shipping_method]
      @fulfillment_tracking_number = options[:tracking_number]
      @items = items
    end

    def to_xml(name='OrderFulfillment', parent = nil)
      Mws::Serializer.tree name, parent do |xml|
        xml.AmazonOrderID @amazon_order_id
        xml.MerchantOrderID @merchant_order_id if @merchant_order_id
        xml.MerchantFulfillmentID @merchant_fulfillment_id if @merchant_fulfillment_id
        xml.FulfillmentDate @fulfillment_date if @fulfillment_date
        xml.FulfillmentData do
          xml.CarrierCode @fulfillment_carrier_code
          xml.ShippingMethod @fulfillment_shipping_method
          xml.ShipperTrackingNumber @fulfillment_tracking_number
        end
        items.each do |item|
          xml.Item do
            xml.AmazonOrderItemCode item.amazon_item_id
            xml.MerchantOrderItemID item.id
            xml.MerchantFulfillmentItemID '12345'
            xml.Quantity item.quantity
          end
        end
      end
    end
  end
end

