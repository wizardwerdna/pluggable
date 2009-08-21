$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'singleton'
require 'forwardable'
module Pluggable
  
  class Plugins < Array
    extend Forwardable
    def self.from_array_of_instance_and_name_pairs array
      result = new
      array.each do |each_pair| 
        result << each_pair[:instance]
        result.instance_variable_set each_pair[:name], each_pair[:instance]
      end
      result
    end
  end
  
  class PluginFactory < Array
    include Singleton
    def build_plugins
      array_of_instance_and_name_pairs = map do |each| 
        instance = each.new
        {:name => variable_name_for_plugin_instance(instance), :instance => instance}
      end
      Plugins.from_array_of_instance_and_name_pairs(array_of_instance_and_name_pairs)
    end
    def delegate_plugin_public_methods_to_plugins_class_except *excluded_methods
      excluded_methods = excluded_methods.map{|each| each.to_s}
      build_plugins.each do |instance|
        delegated_methods = instance.public_methods-Plugin.public_instance_methods-excluded_methods
        variable_name = variable_name_for_plugin_instance instance
        Plugins.def_delegators variable_name, *delegated_methods
      end
    end
    private
    def variable_name_for_plugin_instance instance
      "@ivar_for_#{instance.class.to_s}".gsub(/::/) {'_colons_'}.to_sym
    end
  end
  
  class Plugin
    def self.inherited(klass)
      PluginFactory.instance << klass
  	end
  end
  
  def install_plugins
    instance_variable_set :@pluggable_module_plugins, PluginFactory.instance.build_plugins
  end

  def plugins
    instance_variable_get :@pluggable_module_plugins
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
  
  module ClassMethods
    def plugin_factory
      PluginFactory.instance
    end
    def delegate_plugin_public_methods_except *excluded_methods
      PluginFactory.instance.delegate_plugin_public_methods_to_plugins_class_except *excluded_methods
    end
  end
end