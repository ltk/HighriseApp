$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'sinatra'
require 'rack-flash'
require 'active_model_monkeypatch'
require 'deal'
require 'visualization'
require 'utility'
require 'pry'

class HighriseApp < Sinatra::Base
  enable :sessions
  use Rack::Flash

  before do
    secrets = YAML.load_file('config/secrets.yml')
    @highrise_url = secrets.fetch('highrise')['site']
    Highrise::Base.site = @highrise_url
    Highrise::Base.user = secrets.fetch('highrise')['api-token']
  end

  get "/deal/:deal_id/edit" do
    @deal = Highrise::Deal.find(params[:deal_id])
    erb :edit
  end

  post "/deal/:deal_id" do
    @deal = Highrise::Deal.find(params[:deal_id])
    @deal.update_forecast_data(request.POST['forecast']) if request.POST['forecast']
    @deal.attributes.reject!{|k,v| k == "party"}
    @deal.load(request.POST["deal"])
    saved = @deal.save()

    if saved
      flash[:success] = "Saved!"
      redirect to("/")
    else
      flash[:error] = "Couldn't save data to Highrise. Try again."
      redirect to("/deal/#{params[:deal_id]}/edit")
    end
  end

  get "/" do
    @deals = Highrise::Deal.find(:all)
    @viz = Visualization.new(@deals, :start_date => Date.today, :end_date => Date.today + 700)
    erb :index
  end

  error do
    'Sorry there was a nasty error - ' + env['sinatra.error'].name
  end
end
