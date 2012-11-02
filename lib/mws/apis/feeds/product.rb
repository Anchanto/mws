module Mws::Apis::Feeds

  class Product

    LengthUnit = Mws::Enum.for(
      inches: 'inches',
      feet: 'feet',
      meters: 'meters',
      decimeters: 'decimeters',
      centimeters:'centimeters',
      millimeters:'millimeters',
      micrometers: 'micrometers',
      nanometers: 'nanometers',
      picometers: 'picometers'
    )

    WeightUnit = Mws::Enum.for(
      grams: 'GR',
      kilograms: 'KG',
      ounces: 'OZ',
      pounds: 'LB',
      miligrams: 'MG'
    )

    CategorySerializer = Mws::Serializer.new do
      ce {
        to { | key, value, doc, path |
          doc.send(key.upcase) do | builder |
            proceed(value, builder, path)
          end
        }
        product_type.cable_or_adapter.cable_length {
          to { | key, value, doc, path |
            doc.send(Mws::Utils.camelize(key), value[:length], unitOfMeasure: value[:unit_of_measure])
          }
        }
      }
    end

    attr_reader :sku, :description

    attr_accessor :upc, :tax_code, :msrp, :brand, :manufacture, :name, :description, :bullet_points
    attr_accessor :item_dimensions, :package_dimensions, :package_weight, :shipping_weight
    attr_accessor :category, :details

    def initialize(sku, &block)
      @sku = sku
      @bullet_points = []
      ProductBuilder.new(self).instance_eval &block if block_given?
    end

    def to_xml(name='Product', parent=nil)
      Mws::Serializer.tree name, parent do |xml|
        xml.SKU @sku
        xml.StandardProductID {
          xml.Type 'UPC'
          xml.Value @upc
        } unless @upc.nil?
        xml.ProductTaxCode @tax_code unless @upc.nil?
        xml.DescriptionData {
          xml.Title @name unless @name.nil?
          xml.Brand @brand  unless @brand.nil?
          xml.Description @description  unless @description.nil?
          bullet_points.each do | bullet_point |
            xml.BulletPoint bullet_point
          end
          @item_dimensions.to_xml('ItemDimensions', xml) unless @item_dimensions.nil?
          @package_dimensions.to_xml('PackageDimensions', xml) unless @item_dimensions.nil?

          @package_weight.to_xml('PackageWeight', xml) unless @package_weight.nil?
          @shipping_weight.to_xml('ShippingWeight', xml) unless @shipping_weight.nil?

          @msrp.to_xml 'MSRP', xml unless @msrp.nil?

          xml.Manufacture @manufacture unless @manufacture.nil?
        }

        unless @details.nil?
          @category ||= :ce
          xml.ProductData {
            CategorySerializer.xml_for @category, {product_type: @details}, xml
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

    class ProductBuilder < DelegatingBuilder

      def initialize(product)
        super product
        @product = product
      end

      def msrp(amount, currency)
        @product.msrp = Mws::Apis::Feeds::MonetaryAmount.new amount, currency
      end

      def item_dimensions(&block)
        @product.item_dimensions = Dimensions.new
        DimensionsBuilder.new(@product.item_dimensions).instance_eval &block if block_given?
      end

      def package_dimensions(&block)
        @product.package_dimensions = Dimensions.new
        DimensionsBuilder.new(@product.package_dimensions).instance_eval &block if block_given?
      end

      def package_weight(value, unit)
        @product.package_weight = Dimension.new value, Dimension.require_valid_weight_unit(unit)
      end

      def shipping_weight(value, unit)
        @product.shipping_weight = Dimension.new value, Dimension.require_valid_weight_unit(unit)
      end

      def bullet_point(bullet_point)
        @product.bullet_points << bullet_point
      end

      def details(details=nil, &block)
        @product.details = details || {}
        DetailBuilder.new(@product.details).instance_eval &block if block_given?
      end

    end

    class Dimensions

      attr_accessor :length, :width, :height, :weight

      def to_xml(name='Dimensions', parent=nil)
        Mws::Serializer.tree name, parent do |xml|
          @length.to_xml 'Length', xml unless @length.nil?
          @width.to_xml 'Width', xml unless @width.nil?
          @height.to_xml 'Height', xml unless @height.nil?
          @weight.to_xml 'Weight', xml unless @weight.nil?
        end
      end

    end

    class Dimension

      attr_reader :value

      def initialize(value, unit)
        @unit = unit
        @value = value
      end

      def unit
        @unit.sym
      end

      def to_xml(name='Dimension', parent=nil)
        Mws::Serializer.leaf name, parent, @value, unitOfMeasure: @unit.val
      end

      def self.require_valid_length_unit(unit)
        raise ArgumentError, "Not a valid unit of length - #{unit}" if LengthUnit.for(unit).nil?
        LengthUnit.for(unit)
      end

      def self.require_valid_weight_unit(unit)
        raise ArgumentError, "Not a valid unit of weight - #{unit}" if WeightUnit.for(unit).nil?
        WeightUnit.for(unit)
      end

    end

    class DimensionsBuilder

      def initialize(dimensions)
        @dimensions = dimensions
      end

      def length(value, unit)
        @dimensions.length = Dimension.new value, Dimension.require_valid_length_unit(unit)
      end

      def width(value, unit)
        @dimensions.width = Dimension.new value, Dimension.require_valid_length_unit(unit)
      end

      def height(value, unit)
        @dimensions.height = Dimension.new value, Dimension.require_valid_length_unit(unit)
      end

      def weight(value, unit)
        @dimensions.weight = Dimension.new value, Dimension.require_valid_weight_unit(unit)
      end
    end

    class DetailBuilder

      def initialize(details)
        @details = details
      end

      def method_missing(method, *args, &block)
        if block_given?
          @details[method] = {}
          DetailBuilder.new(@details[method]).instance_eval(&block)
        elsif args.length > 0
          @details[method] = args[0]
        end
      end

    end

  end
end
