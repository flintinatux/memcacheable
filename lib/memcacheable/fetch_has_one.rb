module Memcacheable
  class FetchHasOne < FetchAssociation
    def fetchable?
      klass.respond_to?(:fetch_by) && klass.cached_indexes.include?(["#{class_name}_id".to_sym])
    end

    def find_on_cache_miss
      criteria = { "#{class_name}_id" => object.id }
      fetchable? ? klass.fetch_by(criteria) : object.send(association)
    end

    def klass
      @klass ||= association.to_s.camelize.constantize
    end
  end
end
