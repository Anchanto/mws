module Mws::Apis::Feeds
  class Relationship

    attr_reader :sku
    attr_accessor :product_relationships

    def initialize(sku, &block)
      @sku = sku
      @product_relationships = []
      RelationshipBuilder.new(self).instance_eval &block if block_given?
    end

    def to_xml(name = 'Relationship', parent = nil)
      Mws::Serializer.tree name, parent do |xml|
        xml.ParentSKU @sku
        @product_relationships.each do |product_relationship|
          xml.Relation {
            xml.SKU product_relationship[:sku]
            #xml.ChildDetailPageDisplay product_relationship[:child_detail_page_display]
            xml.Type product_relationship[:type]
          }
        end
      end
    end

    class DelegatingBuilder

      def initialize(delegate)
        @delegate = delegate
      end

      def method_missing(method, *args, &block)
        @delegate.send("#{method}=", *args, &block) if @delegate.respond_to? "#{method}="
      end
    end

    class RelationshipBuilder < DelegatingBuilder
      def initialize(relationship)
        super relationship
        @relationship = relationship
      end

      def relation(relation)
        @relationship.product_relationships << {
          sku: relation[:sku],
          child_detail_page_display: relation[:child_detail_page_display],
          type: relation[:type]
        }
      end
    end
  end
end
