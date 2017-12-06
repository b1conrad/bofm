ruleset bofm.router {
  meta {
    use module io.picolabs.subscription alias subscription
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
    my_consumers = function() {
      subscription:getSubscriptions(["attributes","subscriber_role"],"consumer")
        .map(function(v){v.values().head()})
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
  rule incoming_verse {
    select when bofm verse
    foreach my_consumers() setting(s)
    pre {
      eci = s{["attributes","outbound_eci"]};
    }
    event:send({"eci":eci, "domain": "bofm", "type": "verse", "attrs": event:attrs()},
      s{["attributes","subscriber_host"]});
  }
}
