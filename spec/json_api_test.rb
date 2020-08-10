require 'net/http'
require 'json'

net = Net::HTTP.new("127.0.0.1",9292)
 # net = Net::HTTP.new("197.189.232.113",8000)
# net = Net::HTTP.new("196.41.123.86",8000)

request = Net::HTTP::Post.new("/campaigns")
json_new_campaign = {campaign: {name: "tes2722", campaign_ref: "tf342x", 
						callees:[{contact_ref: "123ss23"},{contact_ref: "123zxc2qq"}],
						agents:[{extension: "561289"},{extension: "9871a16l54"}]}}

json_new_campaign = {campaign:{name:"YOUR CAMPAIGN NAME HERE",campaign_ref:"adr23ff",status:"started",
	settings:{outbound_call_id:"TF",dial_from_self:"1",dial_aggression:"3",max_attempts:"6",call_timeout:"1",wrapup_time:"9",amd:"false"},
	callees:[{contact_ref:"lloyd_cell",numbers:[{n:"0741484437",p:"1"}]}],agents:[{extension:"2010",status:"available"}]}}

c_ref = "1222"
b_agent = 4000
json_new_campaign = {campaign:{name:"YOUR CAMPAIGN NAME HERE",campaign_ref:"#{c_ref}",status:"stopped",
	settings:{outbound_call_id:"8008580085",dial_from_self:"0",amd:"0",dial_aggression:"1",max_attempts:"60",call_timeout:"0",wrapup_time:"10",retry_timeout:"10",notif_type:"redis",moh:"moh"},
	callees:[{contact_ref:"lloyds_cell-#{c_ref}", status: "pending", numbers:[{n:"0100350909",p:"1"}]},
		{contact_ref:"lloyds_cell2-#{c_ref}", status: "pending", numbers:[{n:"0835721303",p:"1"}]},
		{contact_ref:"aasd-#{c_ref}", status: "pending", numbers:[{n:"0100350909",p:"1"}]},
		{contact_ref:"asdasd-#{c_ref}", status: "pending", numbers:[{n:"0835721303",p:"1"}]}
		# {contact_ref:"sly_cell-#{c_ref}", status: "pending", numbers:[{n:"0835721303",p:"1"}]},
		# {contact_ref:"Telkom-#{c_ref}", status: "pending", numbers:[{n:"0114635132",p:"1"}]},
		# {contact_ref:"andrew_cell-#{c_ref}", status: "pending", numbers:[{n:"0837472866",p:"1"}]},
		# {contact_ref:"lloyd-jnr-cell-#{c_ref}", status: "pending", numbers:[{n:"0737982554",p:"1"}]},
		# {contact_ref:"frans_cell-#{c_ref}", status: "pending", numbers:[{n:"0832673552",p:"1"}]},
		],
		# {contact_ref:"wes_cell-#{c_ref}",numbers:[{n:"0814390282",p:"1"}]},
		# {contact_ref:"tmp1-#{c_ref}",numbers:[{n:"0100350909",p:"1"}]},
		# {contact_ref:"tmp2-#{c_ref}",numbers:[{n:"0100035437",p:"1"}]}],
	agents:[{extension:"#{b_agent}",status:"offline"}]}}



# {extension:"3002",status:"available"},{extension:"3003",status:"available"},

# json_new_campaign = {campaign:{name:"YOUR CAMPAIGN NAME HERE",campaign_ref:"#{c_ref}",status:"started",
# 	settings:{outbound_call_id:"123",dial_from_self:"1",dial_aggression:"1",max_attempts:"6",call_timeout:"1",wrapup_time:"120",retry_timeout:"120"},
# 	callees:[
# 		{contact_ref:"lloyds_cell_#{c_ref}",status: 'pending', numbers:[{n:"0741484437",p:"1"},{n:"0614740730",p:"1"}]}],
# 	agents:[{extension:"2012",status:"available"},{extension:"2013",status:"offline"}]}}

# json_new_campaign = {campaign:{name:"Test2", settings:{dial_aggression:1, max_attempts:30, wrapup_time:300, dial_from_self:0, outbound_call_id:"0113165842", call_timeout:0, hold_timeout:0}, status:"stopped", campaign_ref:"tftest2", agents:[{extension:"2010"}]}}
# json_new_campaign = {campaign:{name:"Teleforge Live Sample 02", settings:{dial_aggression:3, max_attempts:30, wrapup_time:300, dial_from_self:0, outbound_call_id:"0113165811", call_timeout:0, hold_timeout:0}, status:"stopped", campaign_ref:163, agents:[{extension:"4003"}]}}

jsonData = json_new_campaign.to_json

request = Net::HTTP::Post.new("/campaigns")
# # # json_update_campaign = {campaign: {status: "started", agents:[{extension: "5673a289", status: "busy"},{extension: "t1r23", status: "offline"}] }}
 # json_update_campaign = {campaign:{ status: "stopped" }}
 # jsonData = json_update_campaign.to_json

# # request = Net::HTTP::Delete.new("/campaigns/#{c_ref}")
# # jsonData = {}.to_json

# request = Net::HTTP::Put.new("/callees/lloyds_cell_#{c_ref}")
# json_new_callee = {callee: {status: "pending", numbers:[{n:"0741484437",p:"1"}], campaign_ref:"#{c_ref}"}}
# jsonData = json_new_callee.to_json

# request = Net::HTTP::Post.new("/agents")
# json_new_callee = {agent: {extension: "2012", campaign_ref:"adr23ff2w", status:"available"}}
# jsonData = json_new_callee.to_json

# request = Net::HTTP::Put.new("/agents/4000")
# json_update_callee = {agent: {status: :offline}}
# jsonData = json_update_callee.to_json

# request = Net::HTTP::Delete.new("/agents/2010")
# jsonData = {}.to_json

# request = Net::HTTP::Get.new("/campaigns/tf_23457543d")

# request = Net::HTTP::Put.new("/calls/40")
# json_update_callee = {call:{disposition: "C"}}
# jsonData = json_update_callee.to_json

request.set_form_data({"data" => jsonData})
request.set_content_type("application/json")
request.body = jsonData

headers = {"Content-Type" => "applications/json", "Accept-Encoding" => "gzip,deflate", "Accept"=>"application/json"}
net.set_debug_output $stdout
net.read_timeout = 10
net.open_timeout = 10

# response = Net::HTTP.post_form(uri, 'data'=>jsonData)
response = net.start do |http|
	http.request(request)
end

puts response.code
puts response.read_body