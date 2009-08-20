require 'forwardable'
require File.dirname(__FILE__) + '/spec_helper.rb'

class Test
  extend Forwardable
  include Pluggable
  def method_missing symbol, *args
    plugins.send(symbol, *args)
  end
end

class Plugin1 < Test::Plugin
  def foo
    "foo"
  end
  def exception_public
  end
  private
  def exception_private
  end
end

class Plugin2 < Test::Plugin
  def bar
    "bar"
  end
  def exception_public
  end
  private
  def exception_private
  end
end

class Plugin3 < Test::Plugin
  def baz
    "baz"
  end
  def exception_public
  end
  private
  def exception_private
  end
end

Test.new.plugins.delegate_public_methods_to_plugins_except :exception_public

describe Pluggable, "when included in a class" do
  
  before(:each) do
    @test_instance = Test.new
  end
  
  it "adds a plugins method to the class instance returning an instance of Plugins" do
    @test_instance.should respond_to(:plugins)
    @test_instance.plugins.should be_a_kind_of(Test::Plugins)
  end
  
  it "should include instances of all the plugins" do
    @test_instance.plugins.should have(3).items
    @test_instance.plugins.map{|each| each.class}.should include(Plugin1, Plugin2, Plugin3)
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

describe Test, "when using message_missing to simulate delegation from the parent" do
  
  before(:each) do
    @test_instance = Test.new
  end

  it "should delegate public methods of plugins" do
    @test_instance.foo.should == "foo"
    @test_instance.bar.should == "bar"
    @test_instance.baz.should == "baz"
  end
end
