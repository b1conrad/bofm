ruleset bofm.consumer {
  meta {
    shares __testing
  }
  global {
    __testing =
    { "queries": [ { "name": "__testing" }
                 ]
    , "events": [
                ]
    }
  }
  rule initialize {
    select when wrangler ruleset_added where rids >< meta:rid
    if ent:refs.isnull() || ent:txts.isnull() then noop()
    fired {
      ent:refs := {};
      ent:txts := {};
    }
  }
  rule bofm_verse {
    select when bofm verse
    foreach event:attrs setting(txt,ref)
    fired {
      ent:refs{time:now()} := ref;
      ent:txts{ref} := txt;
    }
  }
}
