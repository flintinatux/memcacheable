module Memcacheable
  class FetchOne < Fetcher
    attr_accessor :klass, :id

    def initialize(klass, id)
      self.klass = klass
      self.id = id  
    end

    def cache_key
      [klass.name.downcase, id]
    end

    def description
      "#{klass.name.downcase} #{id}"
    end

    def find_on_cache_miss
      klass.find id
    end
  end
end
