module Mws::Apis::Feeds
  class OrderAcknowledgement

    attr_accessor :amazon_order_id, :merchant_order_id, :status_code, :items

    def initialize(amazon_order_id, merchant_order_id, status_code, items)
      @amazon_order_id = amazon_order_id
      @merchant_order_id = merchant_order_id
      @status_code = status_code
      @items = items
    end

    def to_xml(name='OrderAcknowledgement', parent = nil)
      Mws::Serializer.tree name, parent do |xml|
        xml.AmazonOrderID @amazon_order_id
        xml.MerchantOrderID @merchant_order_id if @merchant_order_id
        xml.StatusCode @status_code
        items.each do |item|
          xml.Item do
            xml.AmazonOrderItemCode item.amazon_item_id
            xml.MerchantOrderItemID item.id
          end
        end
      end
    end
  end
end
