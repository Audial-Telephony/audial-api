module CampainsFactory

  def create_campaign(ref, opt = {})
    json_new_campaign = instantiate_campaign(ref, opt)
    post "/campaigns" , json_new_campaign
  end

  def instantiate_campaign(ref, opt = {})
     {
         "campaign": {
           "name": opt[:name] || "test12722",
           "campaign_ref": ref,
           "status": opt[:status] || "stopped",
           "settings": {
                "outbound_call_id": opt.try(:[],:settings).try(:[],:outbound_call_id) || "27123456789",
                "dial_aggression": opt.try(:[],:settings).try(:[],:dial_aggression) || 3,
                "max_attempts": opt.try(:[],:settings).try(:[],:max_attempts) || 30,
                "retry_timeout": opt.try(:[],:settings).try(:[],:retry_timeout)|| 1800,
                "notif_type": opt.try(:[],:settings).try(:[],:notif_type) || "redis",
                "campaign_type": opt.try(:[],:settings).try(:[],:campaign_type) || "progressive",
                "moh": opt.try(:[],:settings).try(:[],:moh) || "moh",
                "agent_moh": opt.try(:[],:settings).try(:[],:agent_moh) || "moh",
                "amd": opt.try(:[],:settings).try(:[],:amd)|| true
            },
            "callees": opt.try(:[],:callees)  || [],
            "agents": opt.try(:[],:agents)  || []
          }
    }
  end
end



