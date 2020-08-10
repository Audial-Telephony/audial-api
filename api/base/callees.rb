module Dialer
  class Callees < Grape::API
    include StaticVariables

    helpers do
      def params_hash
        params.to_hash.symbolize_keys!
      end

      def callee_params
        params_hash[:callee].symbolize_keys!
      end

      def clean_update_params
          callee_params.select {|k| k == :numbers}
      end

      def find_callee!
        callee = Callee[ref: params_hash[:contact_ref]]
        error!({errors: ["Callee Error: Contact Ref[#{params_hash[:contact_ref]}] does not exist"]}, 404) unless callee
        callee
      end

      def priority_valid!

          if !callee_params[:numbers].blank?
            #invalide_priorities = (callee_params[:numbers].map {|x| x["p"].to_i} - PRIORITY_VALUES).uniq
            invalide_priorities = (callee_params[:numbers].select {|x| (PRIORITY_REGEX =~ x["p"].to_s).nil? }.map{|y| y["p"].to_s} ).uniq
             unless invalide_priorities.size == 0
              numbers = callee_params[:numbers].select {|x| invalide_priorities.include?(x["p"].to_s)}.map{|y| y["n"].to_s}
              error!({errors: ["Callee Error: Invalid priority[#{invalide_priorities.join(',')}] number[#{numbers.join(',')}] for Contact Ref[#{ params_hash[:callee]["contact_ref"] || params_hash[:contact_ref]}]"]},400)
             end
          end
      end

      def phone_number_valid!
        if !callee_params[:numbers].blank?
          invalide_numbers = (callee_params[:numbers].select {|x| (VALID_PHONE_REGEX =~ x["n"].to_s).nil? }.map{|y| y["n"]} ).uniq
          unless invalide_numbers.size == 0
           error!({errors: ["Callee Error: Invalid number[#{invalide_numbers.join(',')}] for Contact Contact Ref[#{params_hash[:callee]["contact_ref"] || params_hash[:contact_ref]}]"]},400)
          end
         end
      end

      def contact_ref_valid!
        if !callee_params[:contact_ref].blank?
          if (VALID_REF_REGEX =~ callee_params[:contact_ref].to_s).nil?
            error!({errors: ["Callee Error: Invalid Contact ref[#{callee_params[:contact_ref]}]"]},400)
          end
        else
          error!({errors: ["Callee Error: Missing field[contact_ref]"]},400)
        end
      end

      def find_campaign(campaign_ref)
        Campaign[ref: campaign_ref]
      end

      def find_campaign!
        campaign_ref = params_hash[:callee]["campaign_ref"]
        campaign = find_campaign(campaign_ref)
        unless campaign
          logger.warn "Could not find a Campaign matching #{campaign_ref}."
          error!({errors: ["Campaign Error: Campaign[#{campaign_ref}] does not exist"]}, 404)
        end
        campaign
      end

      def logger
        Callees.logger
      end
    end

    resource :callees do

      post do
        logger.info "Creating Callee with #{callee_params.inspect}"
        priority_valid!
        phone_number_valid!
        contact_ref_valid!
        find_campaign!
        callee = Callee.create callee_params
        present callee, with: API::Entities::Callees
      end

      params do
        requires :contact_ref, type: String, desc: "unique callee reference number"
      end

      route_param :contact_ref do
        get do
          callee = find_callee!
          present callee, with: API::Entities::Callees, type: :full_callee
        end

        put do
          priority_valid!
          phone_number_valid!
          #find_campaign!
          callee = find_callee!
          logger.info "Updating Callee #{params[:contact_ref]} with params #{callee_params.inspect}"
          callee.update(clean_update_params)
          present callee, with: API::Entities::Callees
        end

        delete do
          callee = find_callee!
          logger.info "Removing Callee #{params[:contact_ref]}"
          callee.destroy
          present callee, with: API::Entities::Callees
        end
      end
    end
  end
end
