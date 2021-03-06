require 'rails_helper'

RSpec.describe ::Api::V1::ExtApp::ContainersController do
  let(:cluster) { create(:cluster) }
  let(:valid_attributes) {
    attributes_for(:container, cluster_id: cluster.id).
      reject{ |k,v| k == :image_alias}.
      merge({ image: 'linux' })
  }

  let(:invalid_attributes) {
    { hostname: "" }
  }

  before(:each) do
    create(:ext_app, access_token: 'abc')
    request.headers['X-Auth-Token'] = 'abc'
  end

  describe 'responds with index' do
    before(:each) do
      @container_1 = create(:container, cluster: cluster)
      @container_2 = create(:container, cluster: cluster)
      @container_3 = create(:container, cluster: cluster)
      @params = {
        cluster_name: cluster.name,
      }
    end

    it "returns appropriate response" do
      get :index, params: @params, as: :json
      expect(response.body).to eq ::Api::V1::ExtApp::ContainerSerializer.new([@container_1, @container_2, @container_3].sort{|x,y| x.hostname <=> y.hostname}).to_h.to_json
    end
  end

  describe 'responds with show' do
    before(:each) do
      @container = create(:container, cluster: cluster)
      @params = {
        cluster_name: cluster.name,
        hostname: @container.hostname
      }
    end

    it "returns appropriate response" do
      get :show, params: @params, as: :json
      @container.reload
      expect(response.body).to eq ::Api::V1::ExtApp::ContainerSerializer.new(@container).to_h.to_json
    end
  end

  describe "POST #create" do
    context "with valid params" do
      before(:each) do
        @params = {
          cluster_name: cluster.name,
          container: valid_attributes
        }
      end

      it "creates a new Container" do
        expect {
          post :create, params: @params
        }.to change(Container, :count).by(1)
      end

      it "redirects to list of containers" do
        post :create, params: @params
        expect(response).to be_successful
      end
    end

    context "with invalid params" do
      it "returns a failed response" do
        @params = {
          cluster_name: cluster.name,
          container: invalid_attributes
        }
        post :create, params: @params
        expect(response.status).to eq 406
      end
    end
  end

  describe 'responds with schedule_deletion' do
    before(:each) do
      @container = create(:container, cluster: cluster)
      @params = {
        cluster_name: cluster.name,
        hostname: @container.hostname
      }
    end

    it "mark object as schedule_deletion in the database" do
      post :schedule_deletion, params: @params, as: :json
      @container.reload
      expect(@container.status).to eq 'SCHEDULE_DELETION'
    end

    it "returns appropriate response" do
      post :schedule_deletion, params: @params, as: :json
      @container.reload
      expect(response.body).to eq ::Api::V1::ExtApp::ContainerSerializer.new(@container).to_h.to_json
    end
  end

  describe 'responds with reschedule' do
    before(:each) do
      @container = create(:container, cluster: cluster)
      @params = {
        cluster_name: cluster.name,
        hostname: @container.hostname
      }
    end

    it "mark object as schedule_deletion in the database" do
      post :reschedule, params: @params, as: :json
      @container.reload
      expect(@container.status).to eq 'SCHEDULE_DELETION'
      expect(Container.last.status).to eq 'PENDING'
    end

    it "should create new container with same data from deleted container" do
      post :reschedule, params: @params, as: :json
      @container.reload
      expect(@container.cluster_id).to eq Container.last.cluster_id
      expect(@container.hostname).to eq Container.last.hostname
    end

    it "returns appropriate response" do
      post :reschedule, params: @params, as: :json
      expect(response.body).to eq ::Api::V1::ExtApp::ContainerSerializer.new(Container.last).to_h.to_json
    end
  end
end
