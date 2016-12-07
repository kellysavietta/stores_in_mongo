module StoresInMongo
  module DocumentMethods
    def reload(*args)
      super
      clear_mongo_cache
      return self
    end

    def clear_mongo_cache
      @mongo_document = nil
    end

    def deep_dup(*args)
      copy = super
      copy.mongo_document = mongo_document.deep_dup
      return copy
    end

    def changed?
      @mongo_dirty || super
    end

    protected

    def mongo_document=(mongo_document)
      @mongo_document = mongo_document
      self[self.mongo_key] = mongo_document.try!(:id)
    end

    private

    def mark_mongo_owner_as_dirty
      @mongo_dirty = true
      return true
    end

    def clear_mongo_owner_dirty
      @mongo_dirty = false
      return true
    end

    def mongo_document_loaded?
      @mongo_document.present?
    end

    def mongo_document(reload = false)
      return @mongo_document if !reload && mongo_document_loaded?
      self.mongo_document = fetch_mongo_document || initialize_mongo_document
    end

    def fetch_mongo_document
      self.mongo_class.where(id: self[self.mongo_key]).first
    end

    def initialize_mongo_document
      self.mongo_class.new
    end

    def save_mongo_document
      return true if !mongo_document_loaded?
      mongo_document.save
      self[self.mongo_key] = mongo_document.id
      mark_mongo_owner_as_dirty
    end

    def destroy_mongo_document
      return true if !mongo_document_loaded?
      mongo_document.destroy
    end      
  end
end