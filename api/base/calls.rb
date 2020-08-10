module Dialer
  class Calls < Grape::API

    helpers do
      def params_hash
        params.to_hash.symbolize_keys!
      end

      def call_params
        params_hash[:call].symbolize_keys!
      end

      def find_call
        # The extension could be in either hash
        CDR[ id: params_hash[:call_id] ]
      end

      def find_call!

        call = find_call
        unless call
          logger.warn "Could not find a Call with ID #{params_hash[:call_id] }."
          error!({errors: ["Call Error: Call ID[#{params_hash[:call_id]}] does not exist"]}, 404)
        end
        call
      end

      def disposition_call(call, code)

        case code
          when 'E'
            call.hangup_call
          when 'H'
            call.hangup_and_remove_number
          when 'C'
            call.close_matter
          when 'R'
            call.retry_number
        end

      end

      def logger
        Calls.logger
      end
    end

    resource :calls do

      params do
        requires :call, type: Hash do
          requires :campaign_ref, type: String, desc: "Campaign Ref"
          requires :number, type: String, desc: "Phone number for which to create the CDR"
        end
      end
      post do
        logger.info "Creating Call with #{call_params.inspect}"
        old_cdr = CDR[number_dialed: call_params[:number]]

        if old_cdr
          callee = old_cdr.callee
          campaign_id = callee.campaign_id
        else
          campaign = Campaign[ref: call_params[:campaign_ref]]
          if campaign
            campaign_id = campaign.id
          else
            error!({errors: ["Campaign Error: Campaign[#{call_params[:campaign_ref]}] does not exist"]}, 404)
          end
          callee = Callee.create campaign_id: campaign_id, last_dialed_at: Time.now, status: 'queued'
        end

        call_obj = CDR.create campaign_id: campaign_id, callee: callee, number_dialed: call_params[:number]
        present call_obj, with: API::Entities::CDR
      end

      params do
        requires :call_id, type: String, desc: "Unique call ID"
      end
      resource :recording do
        route_param :call_id do
          get do
            call = find_call!

            if call.recording_url && File.exist?( call.recording_url )
              ext = File.extname(call.recording_url)
              content_type 'application/octet-stream'
              header['Content-Disposition'] = "attachment; filename=#{call.id}#{ext}"
              env['api.format'] = :binary
              File.open(call.recording_url ).read
            else
              error!({errors: ["Call Error: Recording not found"]}, 404)
            end

          end
        end
      end

      route_param :call_id do
        params do
          requires :call, type: Hash do
            requires :disposition, type: String, desc: "Disposition code"
          end
        end

        put do

          unless ["E", "H", "C", "R"].include?(call_params[:disposition]) #todo this list should be refactored in static module
            error!({errors: ["Call Error: Invalid Disposition[#{call_params[:disposition]}]"]}, 400)
          end
          call = find_call!
          logger.info "Disposition call #{call.number_dialed} with code #{call_params[:disposition]}."
          disposition_call(call, call_params[:disposition])
        end
      end

    end

  end
end
