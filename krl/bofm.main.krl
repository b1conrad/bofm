ruleset bofm.main {
  meta {
    use module bofm.random alias bofm
    use module io.picolabs.subscription alias subscription
    shares __testing, verse
  }
  global {
    __testing =
    { "queries":
      [ { "name": "__testing" }
      , { "name": "verse" }
      ]
    , "events":
      [ { "domain": "bofm", "type": "test" }
      , { "domain": "bofm", "type": "start_request", "attrs": [ "minutes" ] }
      , { "domain": "bofm", "type": "idle_request" }
      , { "domain": "bofm", "type": "new_consumer", "attrs": [ "did" ] }
      ]
    }
    verse = function() {
      verses = bofm:verse().map(function(v,r){<<  <dt>#{r}</dt>
  <dd>#{v}</dd>
>>                              })
                           .values()
                           .join("");
      <<<dl style="width:400">
#{verses}</dl>
>>
    }
    my_routers = function() {
      subscription:getSubscriptions(["attributes","subscriber_role"],"router")
        .map(function(v){v.values().head()})
    }
  }
  rule initialize {
    select when wrangler ruleset_added where rids >< meta:rid
    pre {
      bofmBase = meta:rulesetURI;
      bofmURL = "bofm.router.krl";
    }
    engine:registerRuleset(bofmURL,bofmBase);
    fired {
      raise wrangler event "new_child_request"
        attributes { "dname": "bofm router", "color": "#87cefa",
                     "rids": "bofm.router;io.picolabs.subscription" };
      raise wrangler event "install_rulesets_requested"
        attributes { "rids": "io.picolabs.subscription" };
    }
  }
  rule new_router {
    select when wrangler child_initialized
    pre {
      child_eci = event:attr("eci");
    }
    noop();
    fired {
    }
    finally {
      raise wrangler event "subscription" attributes
        { "name" : "to_router",
          "name_space" : "bofm",
          "my_role" : "generator",
          "subscriber_role" :"router",
          "channel_type" : "subscription",
          "subscriber_eci" : child_eci
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
    event:send({"eci":eci, "domain": "bofm", "type": "verse", "attrs": event:attrs()});
  }
  rule bofm_new_consumer {
    select when bofm new_consumer did re#(.+)# setting(consumer_eci)
    pre {
      router_eci = my_routers().head(){["attributes","subscriber_eci"]};
    }
    event:send(
      { "eci": consumer_eci, "eid": "subscription",
        "domain": "wrangler", "type": "subscription",
        "attrs": { "name": "consumer",
                   "name_space": "bofm",
                   "my_role": "consumer",
                   "subscriber_role": "router",
                   "channel_type": "subscription",
                   "subscriber_eci": router_eci } } )
  }
}
