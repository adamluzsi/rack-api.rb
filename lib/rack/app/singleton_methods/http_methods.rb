module Rack::App::SingletonMethods::HttpMethods

  def get(path = '/', &block)
    add_route('GET', path, &block)
  end

  def post(path = '/', &block)
    add_route('POST', path, &block)
  end

  def put(path = '/', &block)
    add_route('PUT', path, &block)
  end

  def head(path = '/', &block)
    add_route('HEAD', path, &block)
  end

  def delete(path = '/', &block)
    add_route('DELETE', path, &block)
  end

  def options(path = '/', &block)
    add_route('OPTIONS', path, &block)
  end

  def patch(path = '/', &block)
    add_route('PATCH', path, &block)
  end

  def alias_endpoint(new_request_path, original_request_path)
    router.endpoints.select { |ep| ep[:request_path] == original_request_path }.each do |endpoint|
      router.register_endpoint!(endpoint[:request_method], new_request_path, endpoint[:description], endpoint[:endpoint])
    end
  end

  def serve_files_from(file_path, options={})
    file_server = Rack::App::FileServer.new(Rack::App::Utils.expand_path(file_path))
    request_path = Rack::App::Utils.join(@namespaces, options[:to], '**', '*')
    router.register_endpoint!('GET', request_path, @last_description, file_server)
    @last_description = nil
  end

end
