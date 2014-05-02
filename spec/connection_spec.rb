require 'spec_helper'

describe Fog::Core::Connection do 
  it "raises ArgumentError when no arguments given" do
    assert_raises(ArgumentError) do
      Fog::Core::Connection.new
    end
  end

  [:request, :reset].each do |method|
    it "responds to #{method}" do
      connection = Fog::Core::Connection.new("http://example.com")
      assert connection.respond_to?(method)
    end
  end

  it "writes the Fog::VERSION to the User-Agent header" do
    connection = Fog::Core::Connection.new("http://example.com")
    assert_equal "fog/#{Fog::VERSION}", 
      connection.instance_variable_get(:@excon).data[:headers]["User-Agent"]
  end

  it "doesn't error when persistence is enabled" do
    Fog::Core::Connection.new("http://example.com", true)
  end

  it "doesn't error when persistence is enabled and debug_response is disabled" do
    options = {
      :debug_response => false
    }
    Fog::Core::Connection.new("http://example.com", true, options)
  end

  describe ":base_path" do
    it "does not emit a warning when provided this argument in the initializer" do
      $stderr = StringIO.new
      
      Fog::Core::Connection.new("http://example.com", false, :base_path => "foo")
      
      assert_empty($stderr.string)
    end

    it "raises when the 'path' arg is present when this arg is supplied" do
      assert_raises(ArgumentError) do
        Fog::Core::Connection.new("http://example.com", false, :base_path => "foo", :path => "bar")
      end
    end

    it "supplies the 'path' arg to Excon when 'base_path' is absent" do
      spy = Object.new
      spy.instance_eval do
        def params
          @params
        end
        def new(_, params)
          @params = params
        end
      end

      Object.stub_const("Excon", spy) do
        c = Fog::Core::Connection.new("http://example.com", false, :path => "bar")
        assert_equal("bar", spy.params[:path])
      end
    end
  end

  describe "#request" do
    let(:spy) {
      Object.new.tap { |spy|
        spy.instance_eval do
          def new(*args); self; end
          def params; @params; end
          def request(params)
            @params = params
          end
        end
      }
    }

    it "uses the initializer-supplied :base_path arg with #request :arg to formulate a path to send to Excon.request" do
      Object.stub_const("Excon", spy) do
        c = Fog::Core::Connection.new("http://example.com", false, :base_path => "foo")
        c.request(:path => "bar")
        assert_equal("foo/bar", spy.params[:path])
      end
    end
    
    it "does not introduce consecutive '/'s into the path if 'path' starts with a '/'" do
      Object.stub_const("Excon", spy) do
        c = Fog::Core::Connection.new("http://example.com", false, :base_path => "foo")
        c.request(:path => "/bar")
        assert_equal("foo/bar", spy.params[:path])
      end
    end
  end
end
