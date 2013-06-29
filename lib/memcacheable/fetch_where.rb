module Memcacheable
  class FetchWhere < FetchByCriteria
    def cache_key
      {what: klass.name.tableize}.merge criteria
    end

    def description
      "#{klass.name.tableize} with #{criteria.inspect}"
    end

    def find_on_cache_miss
      klass.where(criteria).to_a
    end
  end
end
