module Memcacheable
  class FetchMethod < Fetcher
    attr_accessor :object, :method, :args

    def initialize(object, method, args)
      self.object = object
      self.method = method
      self.args = args
    end

    def cache_key
      [object, method, args]
    end

    def description
      "method #{cache_key.to_param}"
    end

    def find_on_cache_miss
      object.send method, *args
    end
  end
end
