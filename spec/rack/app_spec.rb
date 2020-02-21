require 'spec_helper'
describe Rack::App do

  let(:request_path) { '/some/endpoint/path' }
  let(:block) { Proc.new {} }

  describe '.router' do
    subject { described_class.router }

    it { is_expected.to be_a Rack::App::Router }
  end

  require 'rack/app/test'
  include Rack::App::Test
  rack_app

  [:get, :post, :put, :delete, :patch, :options].each do |http_method|
    describe ".#{http_method}" do

      rack_app do

        send http_method, "/hello_#{http_method}" do
          String(http_method)
        end

      end

      subject { send(http_method, {:url => "/hello_#{http_method}"}) }

      it { expect(subject.body).to eq String(http_method) }

    end
  end

  let(:request_env) { {} }
  let(:request) { Rack::Request.new(request_env) }
  let(:response) { Rack::Response.new }

  let(:new_subject) {
    instance = described_class.new
    instance.request = request
    instance.response = response
    instance
  }

  describe '#request' do
    subject { new_subject.request }
    context 'when request is set' do
      before { new_subject.request = request }

      it { is_expected.to be request }
    end

    context 'when request is not set' do
      before { new_subject.request = nil }

      it { expect { subject }.to raise_error("request object is not set for #{described_class}") }
    end

  end

  describe '#response' do
    subject { new_subject.response }
    context 'when request is set' do
      before { new_subject.response = response }

      it { is_expected.to be response }
    end

    context 'when request is not set' do
      before { new_subject.response = nil }

      it { expect { subject }.to raise_error("response object is not set for #{described_class}") }
    end

  end

  describe '#response' do
    subject { new_subject.response }
    it { is_expected.to be response }
  end

  describe '#payload' do
    include Rack::App::Test

    rack_app do
      get '/' do
        payload
      end
    end

    it { expect(get('/', :payload => "hello\nworld").body).to eq "hello\nworld" }
  end

  describe '.call' do

    rack_app do

      get '/hello' do
        response.status = 201

        'valid_endpoint'
      end

    end

    subject { ::Rack::MockRequest.new(rack_app).get(path_info) }

    context 'when there is a valid endpoint for the request' do
      let(:path_info) { '/hello' }

      it { expect(subject.body).to eq 'valid_endpoint' }

      it { expect(subject.status).to eq 201 }
    end

    context 'when there is no endpoint registered for the given request' do
      let(:path_info) { '/unknown/endpoint/path' }

      it { expect(subject.body).to eq '404 Not Found' }

      it { expect(subject.status).to eq 404 }
    end

  end

  describe '.serializer' do

    context 'when no serializer defined' do

      rack_app do

        get '/serialized' do
          'to_s'
        end

      end

      it { expect(get(:url => '/serialized').body).to eq 'to_s' }

    end

    context 'when serializer is defined' do

      rack_app do

        serializer do |o|
          o.inspect.upcase
        end

        get '/serialized' do
          {:hello => :world}
        end

      end

      it { expect(get(:url => '/serialized').body).to eq '{:HELLO=>:WORLD}' }

    end

  end


  describe '.error' do

    rack_app do

      error ArgumentError, RangeError do |ex|
        ex.message
      end

      error StandardError do |ex|
        response.status = 400
        'standard'
      end

      get '/handled_exception1' do
        raise(RangeError, 'range')
      end

      get '/handled_exception2' do
        raise(NoMethodError, 'arg')
      end

      get '/unhandled_exception' do
        raise(Exception, 'unhandled')
      end

    end

    context 'when expected error class raised' do
      it { expect(get(:url => '/handled_exception1').body).to eq 'range' }
    end

    context 'when a subclass of the expected error class raised' do
      subject { get(:url => '/handled_exception2') }

      it { expect(subject.body).to eq 'standard' }

      it { expect(subject.status).to eq 400 }
    end

    context 'when one of the unhandled exception happen in the endpoint' do
      it { expect { get(:url => '/unhandled_exception') }.to raise_error(Exception, 'unhandled') }
    end

  end

  describe '#respond_with' do

    rack_app do

      get '/return' do
        respond_with 'hello world'

        'not happen'
      end

    end

    it { expect(get(:url => '/return').body).to eq 'hello world' }

  end

  describe '.serve_files_from' do

    rack_app do

      serve_files_from '/spec/fixtures'

    end

    it { expect(get(:url => '/raw.txt').body).to eq "hello world!\nhow you doing?" }

  end

  describe '.mount_directory' do

    rack_app do

      mount_directory '/spec/fixtures', :to => '/static'
      mount_directory '/spec/fixtures', :to => '/dynamic/:id'

    end

    it { expect(get(:url => '/static/raw.txt').status).to eq 200 }

    it { expect(get(:url => '/static/raw.txt').body).to eq "hello world!\nhow you doing?" }

    it { expect(get(:url => '/dynamic/123/raw.txt').status).to eq 200 }

    it { expect(get(:url => '/dynamic/123/raw.txt').body).to eq "hello world!\nhow you doing?" }

  end

  describe '.middlewares' do

    context 'when middleware setting is between endpoints' do

      rack_app do

        get '/before_middlewares_block_part' do
          request.env['custom']
        end

        middlewares do |builder|
          builder.use(SampleMiddleware, 'custom', 'value')
        end

        get '/after_middlewares_block_part' do
          request.env['custom']
        end

      end

      it { expect(get(:url => '/before_middlewares_block_part').body).to eq 'value' }
      it { expect(get(:url => '/after_middlewares_block_part').body).to eq 'value' }
    end

    context 'when middleware setting is after endpoints' do

      rack_app do

        get '/a' do
          request.env['custom']
        end

        get '/b' do
          request.env['custom']
        end

        middlewares do
          use(SampleMiddleware, 'custom', 'value')
        end

      end

      it { expect(get(:url => '/a').body).to eq 'value' }
      it { expect(get(:url => '/b').body).to eq 'value' }

    end

  end


end
