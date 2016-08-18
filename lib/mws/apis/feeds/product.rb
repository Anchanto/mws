module Mws::Apis::Feeds

  class Product

    CategorySerializer = Mws::Serializer.new ce: 'CE', fba: 'FBA', eu_compliance: 'EUCompliance'

    attr_reader :sku, :description

    attr_accessor :upc, :upc_type, :tax_code, :msrp, :brand, :manufacturer,
                  :name, :description, :bullet_points, :item_type, :launch_date,
                  :item_dimensions, :package_dimensions, :package_weight,
                  :shipping_weight, :category, :details, :condition_type,
                  :mfr_part_number, :search_terms, :used_fors,
                  :other_item_attributes, :target_audiences,
                  :recommended_browse_nodes, :variation_data,
                  :release_date, :classification_data

    def initialize(sku, &block)
      @sku = sku
      @bullet_points = []
      @search_terms = []
      @used_fors = []
      @other_item_attributes = []
      @target_audiences = []
      @recommended_browse_nodes = []
      ProductBuilder.new(self).instance_eval &block if block_given?

      if @details and @category.nil?
        raise Mws::Errors::ValidationError, 'Product must have a category when details are specified.'
      end
    end

    def to_xml(name='Product', parent=nil)
      Mws::Serializer.tree name, parent do |xml|
        xml.SKU @sku
        xml.StandardProductID {
          xml.Type @upc_type
          xml.Value @upc
        } unless @upc.nil?

        xml.ProductTaxCode @tax_code unless @upc.nil?
        xml.LaunchDate @launch_date unless @launch_date.nil?
        xml.ReleaseDate @release_date unless @release_date.nil?
        xml.Condition {
          xml.ConditionType @condition_type
        } unless @condition_type.nil?

        xml.DescriptionData {
          xml.Title @name unless @name.nil?
          xml.Brand @brand  unless @brand.nil?
          xml.Description @description  unless @description.nil?
          bullet_points.each do |bullet_point|
            xml.BulletPoint bullet_point
          end
          @item_dimensions.to_xml('ItemDimensions', xml) unless @item_dimensions.nil?
          @package_dimensions.to_xml('PackageDimensions', xml) unless @item_dimensions.nil?

          @package_weight.to_xml('PackageWeight', xml) unless @package_weight.nil?
          @shipping_weight.to_xml('ShippingWeight', xml) unless @shipping_weight.nil?

          @msrp.to_xml 'MSRP', xml unless @msrp.nil?

          xml.Manufacturer @manufacturer unless @manufacturer.nil?
          xml.MfrPartNumber @mfr_part_number unless mfr_part_number.nil?
          search_terms.each do |search_term|
            xml.SearchTerms search_term
          end
          used_fors.each do |used_for|
            xml.UsedFor used_for
          end
          xml.ItemType @item_type unless @item_type.nil?

          other_item_attributes.each do |other_item_attribute|
            xm.OtherItemAttributes other_item_attribute
          end

          target_audiences.each do |target_audience|
            xm.TargetAudience target_audience
          end

          recommended_browse_nodes.each do |recommended_browse_node|
            xm.RecommendedBrowseNode recommended_browse_node
          end
        }

        details = {}
        details[:product_type] = @details if @details.present?
        details[:variation_data] = @variation_data if @variation_data.present?
        details[:classification_data] = @classification_data if @classification_data.present?

        xml.ProductData {
          CategorySerializer.xml_for @category, details, xml
        } unless details.blank?
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
        @product.msrp = Money.new amount, currency
      end

      def item_dimensions(&block)
        @product.item_dimensions = Dimensions.new
        DimensionsBuilder.new(@product.item_dimensions).instance_eval &block if block_given?
      end

      def package_dimensions(&block)
        @product.package_dimensions = Dimensions.new
        DimensionsBuilder.new(@product.package_dimensions).instance_eval &block if block_given?
      end

      def package_weight(value, unit=nil)
        @product.package_weight = Weight.new(value, unit)
      end

      def shipping_weight(value, unit=nil)
        @product.shipping_weight = Weight.new(value, unit)
      end

      def bullet_point(bullet_point)
        @product.bullet_points << bullet_point
      end

      def search_term(search_term)
        @product.search_terms << search_term
      end

      def used_for(used_for)
        @product.used_fors << used_for
      end

      def other_item_attribute(other_item_attribute)
        @product.other_item_attributes << other_item_attribute
      end

      def target_audience(target_audience)
        @product.target_audiences << target_audience
      end

      def recommended_browse_node(recommended_browse_node)
        @product.recommended_browse_nodes << recommended_browse_node
      end

      def details(details = nil, &block)
        @product.details = details || {}
        DetailBuilder.new(@product.details).instance_eval &block if block_given?
      end

      def variation_data(variation_data = nil, &block)
        @product.variation_data = variation_data || {}
        VariationBuilder.new(@product.variation_data).instance_eval &block if block_given?
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

    class DimensionsBuilder

      def initialize(dimensions)
        @dimensions = dimensions
      end

      def length(value, unit=nil)
        @dimensions.length = Distance.new(value, unit)
      end

      def width(value, unit=nil)
        @dimensions.width = Distance.new(value, unit)
      end

      def height(value, unit=nil)
        @dimensions.height = Distance.new(value, unit)
      end

      def weight(value, unit=nil)
        @dimensions.weight = Weight.new(value, unit)
      end
    end

    class DetailBuilder

      def initialize(details)
        @details = details
      end

      def as_distance(amount, unit=nil)
        Distance.new amount, unit
      end

      def as_weight(amount, unit=nil)
        Weight.new amount, unit
      end

      def as_money(amount, currency=nil)
        Money.new amount, currency
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

    class VariationBuilder
      def initialize(variation_data)
        @variation_data = variation_data
      end

      def variation_theme(value)
        @variation_data[:variation_theme] = value
      end

      def parentage(value)
        @variation_data[:parentage] = value
      end

      def size(value)
        @variation_data[:size] = value
      end

      def color(value)
        @variation_data[:color] = value
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

    class ClassificationBuilder
      def initialize(variation_data)
        @classificaiton_data = classificaiton_data
      end

      def clothing_type(value)
        @classificaiton_data[:clothing_type] = value
      end

      def department(value)
        @classificaiton_data[:department] = value
      end

      def model_number(value)
        @classificaiton_data[:model_number] = value
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
