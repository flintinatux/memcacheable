require 'active_model'
require 'active_record'
require 'active_support'
require 'memcacheable'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join File.dirname(__FILE__), 'support/**/*.rb'].each {|f| require f}
