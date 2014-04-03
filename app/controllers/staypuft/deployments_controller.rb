module Staypuft
  class DeploymentsController < ApplicationController
    include Foreman::Controller::AutoCompleteSearch

    def index
      @deployments = Deployment.search_for(params[:search], :order => params[:order]).paginate(:page => params[:page]) || nil
    end

    def new
      if Deployment.first
        flash[:warning] = _('Deployment already exists.')
        redirect_to deployments_url
        return
      end

      # TODO get the hostgroup base id from settings
      base_hostgroup = Hostgroup.where(:name => 'base_hostgroup').first or
          raise 'missing base_hostgroup'

      deployment             = Deployment.new(:name => Deployment::NEW_NAME_PREFIX+SecureRandom.hex)
      deployment.layout      = Layout.where(:name       => "Distributed",
                                            :networking => "neutron").first
      deployment_hostgroup   = ::Hostgroup.nest deployment.name, base_hostgroup
      deployment_hostgroup.save!

      deployment.hostgroup = deployment_hostgroup
      deployment.save!

      redirect_to deployment_steps_path
    end

    def show
      @deployment = Deployment.find(params[:id])
    end

    def destroy
      Deployment.find(params[:id]).destroy
      process_success
    end

    def deploy
      task = ForemanTasks.async_task ::Actions::Staypuft::Deployment::Deploy, Deployment.first
      redirect_to foreman_tasks_task_url(id: task)
    end

    # TODO remove, it's temporary
    def populate
      task = ForemanTasks.async_task ::Actions::Staypuft::Deployment::Populate, Deployment.first, fake: !!params[:fake]
      redirect_to foreman_tasks_task_url(id: task)
    end

  end
end
