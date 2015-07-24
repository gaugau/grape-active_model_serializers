require 'spec_helper'
require 'grape-active_model_serializers/formatter'

describe Grape::Formatter::ActiveModelSerializers do
  subject { Grape::Formatter::ActiveModelSerializers }

  describe 'serializer options from namespace' do
    let(:app) { Class.new(Grape::API) }

    before do
      app.format :json
      app.formatter :json, Grape::Formatter::ActiveModelSerializers

      app.namespace('space') do |ns|
        ns.get('/', root: false) do
          { user: { first_name: 'JR', last_name: 'HE' } }
        end
      end
    end

    it 'should read serializer options like "root"' do
      expect(described_class.build_options_from_endpoint(app.endpoints.first)).to include :root
    end
  end

  describe '.fetch_serializer' do
    let(:user) { User.new(first_name: 'John') }

    if Grape::Util.const_defined?('InheritableSetting')
      let(:endpoint) { Grape::Endpoint.new(Grape::Util::InheritableSetting.new, path: '/', method: 'foo', root: false) }
    else
      let(:endpoint) { Grape::Endpoint.new({}, path: '/', method: 'foo', root: false) }
    end

    let(:env) { { 'api.endpoint' => endpoint } }

    before do
      def endpoint.current_user
        @current_user ||= User.new(first_name: 'Current user')
      end
    end

    subject { described_class.fetch_serializer(user, env) }

    it { should be_a ActiveModel::Serializer::Adapter::JsonApi }

    it 'should have correct serializer set' do
      expect(subject.serializer).to be_a UserSerializer
    end

    it 'should have correct scope set' do
      expect(subject.serializer.scope.current_user).to eq(endpoint.current_user)
    end

    it 'should read serializer options like "root"' do
      expect(described_class.build_options_from_endpoint(endpoint).keys).to include :root
    end
  end
end
