require 'forwardable'
require File.dirname(__FILE__) + '/spec_helper.rb'

class Test
  include Pluggable
  def process
    plugins.map{|each| each.process}
  end
  private
  def method_missing symbol, *args
    plugins.send(symbol, *args)
  end
end

class Plugin1 < Test::Plugin
  def foo; "foo"; end
  def process; foo; end
  private 
  def exception_private; end
end

class Plugin2 < Test::Plugin
  def bar; "bar"; end
  def process; bar; end
  private
  def exception_private; end
end

class Plugin3 < Test::Plugin
  def baz; "baz"; end
  def process; baz; end
  private
  def exception_private; end
end

if Test.respond_to? :delegate_plugin_public_methods_except
  Test.delegate_plugin_public_methods_except :exception_public
end


describe Pluggable, "when included in a class" do
  
  before(:each) do
    @test_instance = Test.new
  end
  
  it "should install a class method #plugin_factory, an array of all the plugin classes" do
    Test.should respond_to(:plugin_factory)
    Test.plugin_factory.should have(3).items
    Test.plugin_factory.should include(Plugin1, Plugin2, Plugin3)
  end
  
  it "should add a method #plugins that should be nil upon creation" do
    @test_instance.should respond_to(:plugins)
    @test_instance.plugins.should be_nil
  end
  
  it "should add a method #install_plugins" do
    Test.new.should respond_to(:install_plugins)
  end
  
  it "should install a class method #delegate_plugin_public_methods_except" do
    Test.should respond_to(:delegate_plugin_public_methods_except)
  end
end

describe Pluggable, "after installing plugins" do
  before(:each) do
    @test_instance = Test.new
    @test_instance.install_plugins
  end
  
  it "should have #plugins answer an object containing a collection of new plugin instances after #install_plugins" do
    @test_instance.should_not be_nil
    @test_instance.plugins.should_not be_nil
    @test_instance.plugins.should be_an_instance_of(Test::Plugins)
    @test_instance.plugins.should have(3).items
    @test_instance.plugins.map{|each| each.class}.should include(Plugin1, Plugin2, Plugin3)
  end
  
  it "should have #plugins answer an object containing a collection of new plugin instances after #install_plugins a second time" do
    @test_instance.should_not be_nil
    @test_instance.plugins.should_not be_nil
    @test_instance.plugins.should be_an_instance_of(Test::Plugins)
    @test_instance.plugins.should have(3).items
    @test_instance.plugins.map{|each| each.class}.should include(Plugin1, Plugin2, Plugin3)
  end
end

describe Pluggable, "after Test has delegated all but excepted plugin public methods" do
  before(:each) do
    @test_instance = Test.new
    @test_instance.install_plugins
  end

  it "should delegate public methods of plugins" do
    @test_instance.plugins.should respond_to(:foo)
    @test_instance.plugins.should respond_to(:bar)
    @test_instance.plugins.should respond_to(:baz)
    @test_instance.plugins.foo.should == "foo"
    @test_instance.plugins.bar.should == "bar"
    @test_instance.plugins.baz.should == "baz"
  end
  
  it "should not delegate excepted public methods of plugins" do
    @test_instance.plugins.should_not respond_to(:exception_public)
    @test_instance.should_not respond_to(:exception_public)
  end
  
  it "should not delegate private methods of plugins" do
    @test_instance.plugins.should_not respond_to(:exception_private)
    @test_instance.should_not respond_to(:exception_private)
  end
end

describe Test::PluginFactory, "instances" do
  before(:each) do
    @instance = Test::PluginFactory.instance
  end
  
  it "should be an array of all the plugins" do
    @instance.should have(3).items
    @instance.should include(Plugin1, Plugin2, Plugin3)
  end
  
  it "should build a Plugins object with fresh instances of each plugin" do
    @installed_plugins = @instance.build_plugins
    @installed_plugins.should be_a_kind_of(Test::Plugins)
    @installed_plugins.should have(3).items
    @installed_plugins.map{|each| each.class}.should include(Plugin1, Plugin2, Plugin3)
  end
end

describe Test, "when using message_missing to simulate delegation from the parent" do
  
  before(:each) do
    @test_instance = Test.new
    @test_instance.install_plugins
  end

  it "should properly process using all the plugins" do
    @test_instance.process.should == ["foo", "bar", "baz"]
  end

  it "should delegate public methods of plugins" do
    @test_instance.foo.should == "foo"
    @test_instance.bar.should == "bar"
    @test_instance.baz.should == "baz"
  end
end