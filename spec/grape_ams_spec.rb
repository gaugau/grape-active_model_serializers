require 'spec_helper'
require 'spec_fakes'
require "grape-active_model_serializers"

describe Grape::ActiveModelSerializers do
  let(:app) { Class.new(Grape::API) }

  before do
    app.format :json
    app.formatter :json, Grape::Formatter::ActiveModelSerializers
  end


  it "should respond with proper content-type" do
    app.get("/home/users", :serializer => UserSerializer) do
      User.new
    end
    get("/home/users")
    last_response.headers["Content-Type"].should == "application/json"
  end

  context 'serializer is set to nil' do
    before do
      app.get("/home", serializer: nil) do
        {user: {first_name: "JR", last_name: "HE"}}
      end
    end
    it 'uses the built in grape serializer' do 
      get("/home")
      last_response.body.should == "{\"user\":{\"first_name\":\"JR\",\"last_name\":\"HE\"}}"
    end
  end

  context "serializer isn't set" do
    before do
      app.get("/home") do
        User.new({first_name: 'JR', last_name: 'HE', email: 'contact@jrhe.co.uk'})
      end
    end

    it 'infers the serializer' do
      get "/home"
      last_response.body.should == "{\"user\":{\"first_name\":\"JR\",\"last_name\":\"HE\"}}"
    end
  end

  it "serializes arrays of objects" do
    app.get("/home") do
      user = User.new({first_name: 'JR', last_name: 'HE', email: 'contact@jrhe.co.uk'})
      [user, user]
    end

    get "/home"
    last_response.body.should == "{\"users\":[{\"first_name\":\"JR\",\"last_name\":\"HE\"},{\"first_name\":\"JR\",\"last_name\":\"HE\"}]}"
  end

  context "models with compound names" do
    it "generates the proper 'root' node for individual objects" do
      app.get("/home") do
        BlogPost.new({title: 'Grape AM::S Rocks!', body: 'Really, it does.'})
      end

      get "/home"
      last_response.body.should == "{\"blog_post\":{\"title\":\"Grape AM::S Rocks!\",\"body\":\"Really, it does.\"}}"
    end

    it "generates the proper 'root' node for serialized arrays" do
      app.get("/home") do
        blog_post = BlogPost.new({title: 'Grape AM::S Rocks!', body: 'Really, it does.'})
        [blog_post, blog_post]
      end

      get "/home"
      last_response.body.should == "{\"blog_posts\":[{\"title\":\"Grape AM::S Rocks!\",\"body\":\"Really, it does.\"},{\"title\":\"Grape AM::S Rocks!\",\"body\":\"Really, it does.\"}]}"
    end
  end

  it "uses namespace options when provided" do
    app.namespace :admin, :serializer => UserSerializer do
      get('/jeff') do
        User.new(first_name: 'Jeff')
      end
    end

    get "/admin/jeff"
    last_response.body.should == "{\"user\":{\"first_name\":\"Jeff\",\"last_name\":null}}"
  end
end

