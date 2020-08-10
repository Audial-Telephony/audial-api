module Dialer
  class Campaigns < Grape::API
    include StaticVariables

    helpers do
      def params_hash
        params.to_hash.symbolize_keys!
      end

      def campaign_ref
        params_hash[:campaign_ref].to_s
      end
  
      def campaign_params
        params_hash[:campaign].symbolize_keys!
      end

      def find_campaign
        Campaign[ref: params_hash[:campaign_ref]]
      end

      def find_campaign!
        campaign = find_campaign
        unless campaign
          logger.warn "Could not find a Campaign matching #{campaign_ref}."
          error!({errors: ["Campaign Error: Campaign[#{campaign_ref}] does not exist"]}, 404)
        end
        campaign
      end

      def campaign_field_valid!(field_name, field_value, valid_values)
        if field_value
          unless valid_values.values.include?(field_value)
            error!({errors: ["Campaign Error: Incorrect value[#{field_value}] for field[#{field_name}]"]}, 400)
          end
        end
      end
  
      def logger
        Campaigns.logger
      end

      def validate_fields_content
        campaign_field_valid!("status", campaign_params[:status], CAMPAIGN_STATUS)
        if campaign_params[:settings]
          campaign_field_valid!("campaign_type", campaign_params[:settings]["campaign_type"], CAMPAIGN_TYPE)
          #campaign_field_valid!("moh", campaign_params[:settings]["moh"], MOH_VALUES)
          #campaign_field_valid!("agent_moh", campaign_params[:settings]["agent_moh"], AGENT_MOH_VALUES)
        end
      end
    end

    resource :campaigns do

      desc "Returns all the campaigns uploaded to the dialer"
      get do 
        campaigns = Campaign.all
        present campaigns, with: API::Entities::Campaigns, as: :campaigns
      end

      post do
        # Always stringify the campaign_ref for consistency
        campaign_params[:campaign_ref] = campaign_params[:campaign_ref].to_s
        logger.info "Creating Campaign from params #{campaign_params.inspect}"
        validate_fields_content
        campaign = Campaign.create campaign_params

        present campaign, with: API::Entities::Campaigns
      end

      params do
        requires :campaign_ref, type: String, desc: "unique campaign reference number"
      end

      route_param :campaign_ref do

        get do
          campaign = find_campaign!
          present campaign, with: API::Entities::Campaigns, type: :full_campaign
        end

        put do
          validate_fields_content
          campaign = find_campaign
          if campaign
            logger.info "Updating Campaign #{campaign_ref} with params #{campaign_params.inspect}"
            campaign.update campaign_params
          else
            logger.info "Creating Campaign #{campaign_ref} from params #{campaign_params.inspect}"
            campaign = Campaign.create campaign_params
          end

          present campaign, with: API::Entities::Campaigns, type: :with_settings
        end

        delete do
          campaign = find_campaign!
          logger.info "Removing Campaign #{campaign_ref}"
          campaign.destroy
          present campaign, with: API::Entities::Campaigns
        end
      end
    end
  end
end
