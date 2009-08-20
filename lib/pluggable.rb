$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'singleton'
require 'forwardable'
module Pluggable
  VERSION = '0.0.1'
  
  def plugins
    Plugins.instance
  end
  
  class Plugins < Array
    include Singleton
    extend Forwardable

    def delegate_public_methods_to_plugins_except *excluded_methods
      excluded_methods = excluded_methods.map{|each| each.to_s}
      each do |instance|
        delegated_methods = instance.public_methods-Plugin.public_instance_methods-excluded_methods
        variable_name = variable_name_for_plugin_instance instance
        instance_variable_set variable_name, instance
        self.class.def_delegators variable_name, *delegated_methods
      end
    end
    private
    def variable_name_for_plugin_instance instance
      "@ivar_for_#{instance.class.to_s}".gsub(/::/) {'_colons_'}.to_sym
    end
  end
  
  class Plugin
    def self.inherited(klass)
      Plugins.instance << klass.new
  	end
  end
end