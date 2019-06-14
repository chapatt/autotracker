require_relative 'web_positioner_frontend.rb'
require_relative 'websocket_middleware.rb'
require_relative 'api_app.rb'

WebPositionerFrontend.instance # Needs to be called once to initialize

app = Rack::Builder.new do
  use WebSocketMiddleware
  map '/api' do
    run APIApp.new
  end
  use Rack::Static, :urls => [""], :root => 'www', :index => 'index.html'
  run Rack::File.new('www')
end

run app
