module StaticVariables

AGENT_STATUS = {offline: "offline",
                available: "available"
               }
CAMPAIGN_STATUS = {started: "started",
                stopped: "stopped"
}
CAMPAIGN_TYPE = {progressive: "progressive"}
NOTIFICATION_TYPE = {redis: "redis"}
MOH_VALUES = {moh: "moh", silence: "silence"}
AGENT_MOH_VALUES = {moh: "moh", silence: "silence", null: nil}


PRIORITY_REGEX = /(-1|^[1-9]+)$/
VALID_PHONE_REGEX = /^(0|27)\d{9}$/
VALID_REF_REGEX = /^(\w|[\.\-_~:]){1,230}$/

end

