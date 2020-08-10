module Dialer
  require_relative '../../lib/campaign_error'


  class Agents < Grape::API

    include StaticVariables

    helpers do
      def params_hash
        params.to_hash.symbolize_keys!
      end

      def find_agent
        ext = params_hash[:extension] || agent_params[:extension] # The extension could be in either hash
        Agent[extension: ext]
      end

      def find_agent!
        agent = find_agent
        unless agent
          logger.warn "Could not find a Agent matching #{params_hash[:extension]}. Disregarding request #{agent_params.inspect}"
          error!({errors: ["Agent Error: Agent[#{params_hash[:extension]}] does not exist"]}, 404)
        end

        parameters = (params_hash[:agent] || params_hash).symbolize_keys!
        if !parameters[:campaign_ref].blank?
          find_campaign!
          campaigns = agent.campaigns.entries.select {|x|
            x[:ref] == parameters[:campaign_ref]
          }
          error!({errors: ["Agent Error: Agent[#{agent[:extension]}] is not in Campaign[#{parameters[:campaign_ref]}]"]}, 404) if campaigns.empty?
        end
        agent
      end

      def find_campaign
        parameters = (params_hash[:agent] || params_hash).symbolize_keys!
        Campaign[ref: parameters[:campaign_ref]]
      end

      def find_campaign!
        campaign = find_campaign
        unless campaign
          parameters = (params_hash[:agent] || params_hash).symbolize_keys!
          logger.warn "Could not find a Campaign matching #{parameters[:campaign_ref]}."
          error!({errors: ["Campaign Error: Campaign[#{parameters[:campaign_ref]}] does not exist"]}, 404)
        end
        campaign
      end

      def agent_params
        (params_hash[:agent] || params_hash).symbolize_keys! #delete has no body payload, params_hash[:agent] == nil
      end

      def logger
        Agents.logger
      end

      def agent_active_in_started_campaign(extension, current_agent_campaign = nil)
        started_campaigns = Campaign.where(status: CAMPAIGN_STATUS[:started]).entries.reject {|c| c.agents.blank?}
                                .map {|c| {agents_extension: c.agents.map(&:extension), campaign_ref: c.campaign_ref}}.select {|c| c[:campaign_ref] != current_agent_campaign.to_s}
        started_campaigns.find {|ext| ext[:agents_extension].include?(extension)}
      end

      def agent_status_valid!
        if agent_params[:status]
          unless AGENT_STATUS.values.include?(agent_params[:status])
            error!({errors: ["Agent Error: Requested invalid status[#{agent_params[:status]}] for Agent[#{agent_params[:extension]}]"]}, 400)
          end
        end
      end

      def agent_active_in_started_campaign!(extension, current_agent_campaign = nil)
        agent_already_active_in_another_campaign = agent_active_in_started_campaign(extension, current_agent_campaign)
        error!({errors: ["Agent Error: Agent[#{extension}] already in Campaign[#{agent_already_active_in_another_campaign[:campaign_ref]}]"]}, 409) if agent_already_active_in_another_campaign
      end

    end

    resource :agents do

      post do
        agent_status_valid! #validate_agent_status!
        agent = find_agent #check_agent_in_campaign!
        if agent
          logger.info "Updating Agent #{agent_params[:extension]} with POST params #{agent_params.inspect}"
          #agent_active_in_started_campaign!(agent_params[:extension], agent_params[:campaign_ref])
          agent.update agent_params
        else
          logger.info "Creating Agent #{agent_params[:extension]} with params #{agent_params.inspect}"
          agent = Agent.create agent_params
        end
        present agent, with: API::Entities::Agents
      end

      params do
        requires :extension, type: String, desc: "unique agent reference number"
        optional :campaign_ref, type: String, desc: "campaign ref number"
      end

      route_param :extension do
        get do
          agent = find_agent!
          present agent, with: API::Entities::Agents, type: :full_agent
        end

        route_param :campaign_ref do
          get do
            agent = find_agent!
            present agent, with: API::Entities::Agents, type: :full_agent, campaign: params_hash[:campaign_ref]
          end

          delete do
            agent = find_agent!
            campaign = find_campaign!
            logger.info "Removing Agent #{params_hash[:extension]} from campaign #{params_hash[:campaign_ref]}"
            agent.remove_campaign campaign
            present agent, with: API::Entities::Agents, type: :with_camps
          end

        end

        put do
          #validate_parameters_consistency!
          agent_status_valid!
          agent = find_agent!
          #TODO - This check can only be done after DIAL-318
          #current_agent_sarted_campaign = agent.campaigns.entries.find {|x| x[:status] == "started"}.try(:campaign_ref)
          #agent_active_in_started_campaign!(params_hash[:extension], current_agent_sarted_campaign)
          logger.info "Updating Agent #{params_hash[:extension]} with PUT params #{agent_params.inspect}"
          agent.update agent_params
          present agent, with: API::Entities::Agents
        end

        delete do
          agent = find_agent!
          logger.info "Removing Agent #{agent_params[:extension]}"
          agent.destroy
          present agent, with: API::Entities::Agents
        end
      end
    end
  end
end
