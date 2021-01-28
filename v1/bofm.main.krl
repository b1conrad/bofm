ruleset bofm.main {
  meta {
    use module bofm.random alias bofm
    use module io.picolabs.subscription alias subs
    shares __testing, verse
  }
  global {
    verse_html = function(v,r) {
      <<  <dt>#{r}</dt>
  <dd>#{v}</dd>
>>
    }
    verse = function() {
      verses = bofm:verse().map(verse_html)
                           .values()
                           .join("");
      <<<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Random verse</title>
</head>
<body>
<dl style="width:400px">
#{verses}</dl>
</body>
</html>
>>
    }
    my_routers = function() {
      subs:enabled("Tx_role","router")
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    fired {
      raise wrangler event "new_child_request"
        attributes { "name": "bofm router", "backgroundColor": "#87cefa"}
    }
  }
  rule new_router {
    select when wrangler child_initialized
    pre {
      child_eci = event:attr("eci");
      bofmBase = meta:rulesetURI;
      bofmRID = "bofm.router";
    }
    event:send({"eci":child_eci,
      "domain":"wrangler", "type":"install_ruleset_request",
      "attrs":{"absoluteURL":bofmBase, "rid":bofmRID}
    })
    fired {
      raise wrangler event "subscription" attributes
        { "name" : "to_router",
          "Rx_role" : "generator",
          "Tx_role" :"router",
          "channel_type" : "subscription",
          "wellKnown_Tx" : child_eci
        }
    }
  }
  rule bofm_idle_request {
    select when bofm idle_request
    if ent:schedule_id then schedule:remove(ent:schedule_id);
    fired {
      clear ent:schedule_id;
      clear ent:minutes;
    }
  }
  rule bofm_start_request {
    select when bofm start_request minutes re#(\d+)# setting(minutes)
    if minutes.as("Number") >= 1 then noop();
    fired {
      ent:minutes := minutes;
      raise bofm event "verse_needed";
      last;
    }
  }
  rule bofm_start_every_minute {
    select when bofm start_request
    fired {
      ent:minutes := 1;
      raise bofm event "verse_needed";
    }
  }
  rule bofm_verse_needed {
    select when bofm verse_needed
    pre {
      v = bofm:verse();
    }
    fired {
      raise bofm event "schedule_bump";
      raise bofm event "verse_to_route" attributes v;
    }
  }
  rule bofm_schedule_bump {
    select when bofm schedule_bump
    fired {
      schedule bofm event "verse_needed" at time:add(time:now(), {"minutes": ent:minutes})
        setting(schedule_id);
      ent:schedule_id := schedule_id;
    }
  }
  rule test {
    select when bofm test
    pre {
      v = bofm:verse();
    }
    send_directive("verse",{"verse":v,"eid":event:eid});
    fired {
      raise bofm event "verse_to_route" attributes v;
    }
  }
  rule bofm_verse_to_route {
    select when bofm verse_to_route
    foreach my_routers() setting(s)
    pre {
      eci = s{["attributes","outbound_eci"]};
    }
    event:send({"eci":eci, "domain": "bofm", "type": "verse", "attrs": event:attrs});
  }
  rule bofm_new_consumer {
    select when bofm new_consumer did re#(.+)# setting(consumer_eci)
    pre {
      router_eci = my_routers().head(){["attributes","subscriber_eci"]};
    }
    event:send(
      { "eci": router_eci, "eid": "new-consumer",
        "domain": "bofm", "type": "new_consumer",
        "attrs": event:attrs.put("consumer_eci",consumer_eci) } )
  }
}
