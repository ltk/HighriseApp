$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'sinatra'
require 'rack-flash'
require 'active_model_monkeypatch'
require 'deal'
require 'utility'

require 'pry'
require 'logger'

ActiveResource::Base.logger = Logger.new(STDOUT)

class HighriseApp < Sinatra::Base
  enable :sessions
  use Rack::Flash

  def boot_highrise
    secrets = YAML.load_file('config/secrets.yml')

    @highrise_url = secrets.fetch('highrise')['site']
    Highrise::Base.site = @highrise_url
    Highrise::Base.user = secrets.fetch('highrise')['api-token']
  end

  get "/deal/:deal_id/edit" do
    boot_highrise
    @deal = Highrise::Deal.find(params[:deal_id])
    erb :edit
  end

  post "/deal/:deal_id" do
    boot_highrise

    @deal = Highrise::Deal.find(params[:deal_id])

    request.POST.each do |type, array|
      array.each do |key, value|
        value = case type
          when "int" then value.to_i
          when "date" then Date.parse(value)
        end
        @deal.forecast_data.send("#{key}=", value)
      end
    end

    @deal.write_forecast_data
    @deal.attributes.reject!{|k,v| k == "party"}
    saved = @deal.save

    if saved
      flash[:success] = "Saved!"
      redirect to("/")
    else
      flash[:error] = "Couldn't save data to highrise. Try again."
      redirect to("/deal/#{params[:deal_id]}/edit")
    end
  end

  get "/" do
    boot_highrise
    @deals = Highrise::Deal.find(:all)

    erb :index
  end
end
