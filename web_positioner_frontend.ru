require_relative 'web_positioner_frontend.rb'

app = Rack::Builder.new do
  use WebSocketMiddleware
  map '/api' do
    run APIApp.new
  end
  use Rack::Static, :urls => [""], :root => 'www', :index => 'index.html'
  run Rack::File.new('www')
end

run app
