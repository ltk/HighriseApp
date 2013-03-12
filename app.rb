require 'sinatra'

class HighriseApp < Sinatra::Base
  get "/" do
    erb :index
  end
end
