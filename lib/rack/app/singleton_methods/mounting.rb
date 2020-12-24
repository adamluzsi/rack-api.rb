module Rack::App::SingletonMethods::Mounting
  MOUNT = Rack::App::SingletonMethods::Mounting

  def mount(app, options={})
    case
    when app.is_a?(Class) && app < ::Rack::App
      mount_rack_app(app, options)
    when app.respond_to?(:call)
      mount_rack_interface_compatible_application(app, options)
    else
      raise(NotImplementedError)
    end
  end

  def mount_rack_app(app, options={})
    options.freeze

    unless app.is_a?(Class) and app <= Rack::App
      raise(ArgumentError, 'Invalid class given for mount, must be a Rack::App')
    end

    cli.merge!(app.cli)

    merge_prop = {
      :namespaces => [@namespaces, options[:to]].flatten,
      :new_ancestor => self
    }

    router.merge_router!(app.router, merge_prop)

    nil
  end

  def mount_directory(directory_path, options={})

    directory_full_path = ::Rack::App::Utils.expand_path(directory_path)

    namespace options[:to] do
      Dir.glob(File.join(directory_full_path, '**', '*')).each do |file_path|
        request_path = file_path.sub(/^#{Regexp.escape(directory_full_path)}/, '')
        get(request_path) { serve_file(file_path) }
        options(request_path) { '' }
      end
    end

    nil
  end

  def serve_files_from(dir_path, options={})
    file_server = Rack::App::FileServer.new(Rack::App::Utils.expand_path(dir_path))
    request_path = Rack::App::Utils.join(options[:to], Rack::App::Constants::PATH::MOUNT_POINT)
    add_route(::Rack::App::Constants::HTTP::METHOD::ANY, request_path, file_server)
    nil
  end

  def mount_rack_interface_compatible_application(rack_based_app, options={})
    request_path = Rack::App::Utils.join(options[:to],Rack::App::Constants::PATH::APPLICATION)
    add_route(::Rack::App::Constants::HTTP::METHOD::ANY, request_path, rack_based_app)
  end

end
