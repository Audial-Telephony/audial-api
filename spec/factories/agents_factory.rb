module AgentsFactory

  def create_agent(ref)
    create_campaign(ref)
    json_new_agent = {agent: {campaign_ref:ref,  extension:ref, status:"available"} }
    post "/agents" , json_new_agent
  end




end

