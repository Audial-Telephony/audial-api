module CalleesFactory

  def create_callee(ref, opt = {})
    create_campaign(opt.try(:[], :callee).try(:[], :campaign_ref) || ref)
    json_new_callee = {
        callee: {
                  campaign_ref: opt.try(:[], :callee).try(:[], :campaign_ref) || ref,
                  contact_ref: opt.try(:[], :callee).try(:[], :contact_ref) ,
                  numbers: opt.try(:[],:callee).try(:[], :numbers)  || []
        }
    }

    post "/callees" , json_new_callee
  end
end
