ruleset bofm.router {
  meta {
    use module io.picolabs.subscription alias subscription
    shares __testing, consumers
  }
  global {
    __testing =
    { "queries":
      [ { "name": "__testing" }
      , { "name": "consumers" }
      ]
    , "events":
      [ { "domain": "bofm", "name": "new_consumer", "attrs": [ "consumer_eci", "host" ] }
      , { "domain": "bofm", "name": "consumer_removed", "attrs": [ "consumer_eci"] }
      ]
    }
    consumers = function(){
      ent:consumers
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    fired {
      ent:consumers := {};
    }
  }
  rule autoAccept {
    select when wrangler inbound_pending_subscription_added
    pre{
      attributes = event:attrs;
    }
    always{
      raise wrangler event "pending_subscription_approval"
          attributes attributes;
    }
  }
  rule bofm_new_consumer {
    select when bofm new_consumer consumer_eci re#(.+)# setting(consumer_eci)
    fired {
      ent:consumers{consumer_eci} := event:attr("host");
    }
  }
  rule bofm_consumer_removed {
    select when bofm consumer_removed consumer_eci re#(.+)# setting(consumer_eci)
    fired {
      clear ent:consumers{consumer_eci};
    }
  }
  rule incoming_verse {
    select when bofm verse
    foreach ent:consumers setting(host,eci)
    event:send({"eci":eci, "domain": "bofm", "type": "verse", "attrs": event:attrs},
      host);
  }
}
