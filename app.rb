require 'sinatra'
require 'moped'
require 'pry'
require 'json'
require 'base64'

configure do
  mongo_host = ENV['MJ_MONGO_HOSTNAME'] || 'localhost'
  mongo_port = ENV['MJ_MONGO_PORT'] || 27017
  database   = ENV['MJ_DATABASE'] || 'mockjson-dev'
  DB = Moped::Session.new(["#{mongo_host}:#{mongo_port}"])
  DB.use(database)
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def random_string(length)
    rand(36**length).to_s(36)
  end

  def find_entry_by_short_id(short_id)
    DB[:entries].find(short_id: short_id).one
  end
end

get '/' do
  erb :index
end

post '/e' do
  begin
    json = Base64.encode64(params[:entry][:json])
    entry = {short_id: random_string(8)}.merge(json: json)
    raise Exception if find_entry_by_short_id(entry[:short_id])
  rescue
    retry
  end
  DB[:entries].insert(entry)
  redirect to("/e/#{entry[:short_id]}")
end

get '/e/:short_id' do
  @entry = find_entry_by_short_id(params[:short_id])
  halt 404 unless @entry
  erb :entry
end

get '/:short_id' do
  content_type :json
  entry = find_entry_by_short_id(params[:short_id])
  halt 404 unless entry
  Base64.decode64(entry['json'])
end

