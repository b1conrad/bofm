ruleset bofm.router {
  meta {
    use module io.picolabs.subscription alias subscription
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
  }
  rule initialize {
    select when wrangler ruleset_added where rids >< meta:rid
    fired {
      ent:consumers := {};
    }
  }
  rule autoAccept {
    select when wrangler inbound_pending_subscription_added
    pre{
      attributes = event:attrs();
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
  rule incoming_verse {
    select when bofm verse
    foreach ent:consumers setting(host,eci)
    event:send({"eci":eci, "domain": "bofm", "type": "verse", "attrs": event:attrs()},
      host);
  }
}
