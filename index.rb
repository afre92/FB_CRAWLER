require 'sinatra'

class HelloWorldApp < Sinatra::Base
  get '/?:code' do
    "Hello, world!"
  end
end