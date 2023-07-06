require 'net/http'
class UsersController < ApplicationController
  before_action :authenticate_user!
  def index
  end

  def show
    @user = User.find(params[:id])
  end
  

  def new
  end

  def create
  end

  def edit
  end

  def update
  end
  def create_order
    url = URI.parse('https://api-m.sandbox.paypal.com/v1/oauth2/token')
    headers = {
  'Content-Type' => 'application/x-www-form-urlencoded',
  'Authorization' => 'Basic ' + Base64.strict_encode64("#{ENV['PAYPAL_CLIENT_ID']}:#{ENV['PAYPAL_SECRET_ID']}")
   }
body = {
  grant_type: 'client_credentials'
}
parameters = {
  'response_type' => 'token id_token',
}
# Esegui la richiesta POST per ottenere l'access token
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
request = Net::HTTP::Post.new(url.path+"?"+ URI.encode_www_form(parameters), headers)
request.set_form_data(body)
response = http.request(request)

# Controlla se la richiesta ha avuto successo e ottieni l'access token
if response.code == '200'
  
  access_token = JSON.parse(response.body)['access_token']
  puts JSON.parse(response.body)
  # Usa l'access token per le tue richieste successive
else
  # Gestisci l'errore in caso di fallimento della richiesta
  puts "Errore nella richiesta di accesso: #{response.code} - #{response.body}"
end
uri = URI('https://api-m.sandbox.paypal.com/v2/checkout/orders')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri.path)
request['Content-Type'] = 'application/json'

request['Authorization'] = "Bearer #{access_token}"
event_price = 20

payload = {
  intent: 'CAPTURE',
  purchase_units: [
    {
      
      amount: {
        currency_code: 'EUR',
        value: event_price
      }
    }
  ],
  payment_source: {
    paypal: {
      experience_context: {
        payment_method_preference: 'IMMEDIATE_PAYMENT_REQUIRED',
        payment_method_selected: 'PAYPAL',
        landing_page: 'LOGIN',
        user_action: 'PAY_NOW',
        return_url:  "https://localhost/users/:user_id",
        cancel_url: 'https://localhost/users/:user_id'

      }
    }
  }
}

request.body = payload.to_json
response = http.request(request)
puts response.body
links=JSON.parse(response.body)['links']
approve_url=nil
links.each do |link|
  if link['rel'] == 'payer-action'
    approve_url = link['href']
    break
  end
end
puts approve_url
if JSON.parse(response.body)["status"]=="PAYER_ACTION_REQUIRED"
  redirect_to  approve_url,allow_other_host: true
else
  flash[:error]="Errore nel pagamento"
end
end
  def capture_order
    token=params[:token]
    id=params[:PayerID]
    puts id 
    puts token
    capture_url = "https://api-m.sandbox.paypal.com/v2/checkout/orders/#{id}/capture"
    capture_uri = URI.parse(capture_url)
    capture_http = Net::HTTP.new(capture_uri.host, capture_uri.port)
    capture_http.use_ssl = true

    capture_request = Net::HTTP::Post.new(capture_uri.path)
    capture_request['Content-Type'] = 'application/json'
    capture_request['Authorization'] = "Bearer #{token}"
    capture_response = capture_http.request(capture_request)
    puts "Questo è #{capture_response.body}"
    flash[:error]="Hai rifiutato il pagamento"
    render :show

  end

  def destroy
  end
end
