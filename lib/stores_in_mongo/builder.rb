module StoresInMongo
  class Builder

    def initialize(model, field, data_type)
      @model = model
      @field = field.to_s
      @data_type = data_type
    end

    def build
      @model.class_attribute :mongo_data_field
      @model.mongo_data_field = @field

      document_methods = build_document_methods_module
      @model.instance_exec(document_methods, @data_type) do |document_methods, data_type|
        const_set("MongoDocumentMethods", document_methods)
        include self::MongoDocumentMethods

        before_save :save_document
        before_destroy :destroy_document

        mongo_klass = const_set("MongoDocument", Class.new)
        mongo_klass.include Mongoid::Document
        mongo_klass.include Mongoid::Timestamps
        mongo_klass.field self.mongo_data_field.to_sym, :type => data_type, default: data_type.try(:new)
      end
    end

    def build_document_methods_module
      mod = Module.new
      mod.include(StoresInMongo::DocumentMethods)
      mod.instance_exec(@model) do |model|
        define_method(model.mongo_data_field) do |reload = false|
          document(reload)[model.mongo_data_field]
        end

        define_method(model.mongo_data_field + "=") do |data|
          document[model.mongo_data_field] = data
        end
      end
      return mod
    end

  end
end
