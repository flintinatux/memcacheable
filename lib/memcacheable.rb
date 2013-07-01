require 'memcacheable/version'

module Memcacheable
  extend ActiveSupport::Autoload
  extend ActiveSupport::Concern

  autoload :FetchAssociation
  autoload :FetchBelongsTo
  autoload :FetchBy
  autoload :FetchByCriteria
  autoload :FetchHasMany
  autoload :FetchHasOne
  autoload :FetchMethod
  autoload :FetchOne
  autoload :FetchWhere
  autoload :Fetcher
  autoload :Flusher

  included do
    cattr_accessor :cached_indexes do []; end
    after_commit :flush_cache
  end

  def flush_cache
    Flusher.new(self).flush
  end

  def touch
    super
    flush_cache
  end

  module ClassMethods
    def cache_belongs_to(association)
      define_method "fetch_#{association}" do
        FetchBelongsTo.new(self, association).fetch
      end
    end

    def cache_has_one(association)
      define_method "fetch_#{association}" do
        FetchHasOne.new(self, association).fetch
      end
    end

    def cache_has_many(association)
      define_method "fetch_#{association}" do
        FetchHasMany.new(self, association).fetch
      end
    end

    def cache_index(*fields)
      self.cached_indexes << fields.map(&:to_sym).sort
    end

    def cache_method(*methods)
      methods.each do |method|
        define_method "fetch_#{method}" do |*args|
          FetchMethod.new(self, method, args).fetch
        end
      end
    end

    def fetch(id)
      FetchOne.new(self, id).fetch
    end

    def fetch_by(*args)
      FetchBy.new(self, *args).fetch
    end

    def fetch_by!(*args)
      fetch_by(*args) || raise(ActiveRecord::RecordNotFound)
    end

    def fetch_where(*args)
      FetchWhere.new(self, *args).fetch
    end
  end
end
