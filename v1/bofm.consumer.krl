ruleset bofm.consumer {
  meta {
    shares __testing, refs, txts
  }
  global {
    __testing =
    { "queries": [ { "name": "__testing" }
                 , { "name": "refs" }
                 , { "name": "txts", "args": [ "ref" ] }
                 ]
    , "events": [
                ]
    }
    refs = function(){
      ent:refs
    }
    txts = function(ref){
      ref => ent:txts.get(ref) | ent:txts
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
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
