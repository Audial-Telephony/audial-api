module CallsFactory


  def create_call(campaign_ref, number)


    json_new_call = {"call": {"campaign_ref": campaign_ref,  "number": number }}

    post "/calls" , json_new_call
  end


end

