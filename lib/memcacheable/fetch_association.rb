module Memcacheable
  class FetchAssociation < Fetcher
    attr_accessor :object, :association

    def initialize(object, association)
      self.object = object
      self.association = association  
    end

    def cache_key
      [object, association]
    end
    
    def class_name
      object.class.name.downcase
    end

    def description
      "#{association} for #{class_name} #{object.id}"
    end
  end
end
