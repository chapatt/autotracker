require 'rack'

require_relative 'web_positioner_frontend.rb'

class APIApp
  def call(env)
    req = Rack::Request.new(env)

    case req.path_info
    when "/positioners-available"
      mqs = WebPositionerFrontend.instance.positioners_available
      positioners = mqs.collect do
        |id, mq|
        { 'hash' => mq.hash, 'name' => mq.name, 'address' => mq.address, 'port' => mq.port }
      end
      [200, {'Content-Type' => 'text/json'}, [positioners.to_json]]
    when "/positioner"
      if req.get?
        if mq = WebPositionerFrontend.instance.positioner
          mq_json = { 'hash' => mq.hash, 'name' => mq.name, 'address' => mq.address, 'port' => mq.port }.to_json
        else
          mq_json = { }.to_json
	end
        [200, {'Content-Type' => 'text/json'}, [mq_json]]
      elsif req.put?
        mqs = WebPositionerFrontend.instance.positioners_available
        selected_hash = req.body.read.to_i
        selected_positioner = (arr = mqs.find do |id, mq|
          mq.hash == selected_hash
        end) ? arr[1] : nil
        WebPositionerFrontend.instance.positioner = selected_positioner
        [200, {'Content-Type' => 'text/json'}, [""]]
      end
    when "/rel-bearing"
      if req.put?
        bearing = req.body.read.to_i
        WebPositionerFrontend.instance.to_rel_bearing bearing 
        [200, {'Content-Type' => 'text/json'}, [""]]
      end
    else
      [404, {'Content-Type' => 'text/json'}, [{ 'code' => 404, 'message' => 'Not Found' }.to_json]]
    end
  end
end
