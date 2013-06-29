module Memcacheable
  class FetchBy < FetchByCriteria
    def cache_key
      {what: klass.name.downcase}.merge criteria
    end

    def description
      "#{klass.name.downcase} with #{criteria.inspect}"
    end

    def find_on_cache_miss
      klass.find_by criteria
    end
  end
end
