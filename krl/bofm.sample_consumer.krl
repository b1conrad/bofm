ruleset bofm.consumer {
  meta {
    use module bofm.data alias bofm
    shares __testing, refs, refs_page, txt
  }
  global {
    __testing =
    { "queries": [ { "name": "__testing" }
                 , { "name": "refs" }
                 , { "name": "refs_page" }
                 , { "name": "txt", "args": [ "ref" ] }
                 ]
    , "events": [
                ]
    }
    refs = function() {
      ent:refs.values().sort(bofm:ref_cmp)
    }
    ref_option = function(ref) {
      <<    <option>#{ref}</option>
>>
    }
    refs_select = function() {
      <<  <select name="ref">
#{refs().map(function(r){ref_option(r)}).join("")}  </select>
>>
    }
    refs_form = function() {
      eci = engine:listChannels()
            .filter(function(c){c{"name"}=="fragment"&&c{"type"}=="server"})
            .head(){"id"}; //"G1uvSdAPqFRoG8PRf24Nj2";
      <<
<form action="/sky/cloud/#{eci}/bofm.consumer/txt.html">
#{refs_select()}  <input type="submit" value="txt">
</form>
>>
    }
    refs_page = function() {
      timestamps = ent:refs.keys();
      <<<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Collected verses</title>
</head>
<body>
<p>
Collected between #{timestamps.head()}
and #{timestamps[timestamps.length()-1]}
</p>#{refs_form()}</body>
</html>
>>
    }
    txt = function(ref) {
      <<
<dl style="width:400">
  <dt>#{ref}</dt>
  <dd>#{ent:txts{ref}}</dd>
</dl>
>>
    }
  }
  rule initialize {
    select when wrangler ruleset_added where rids >< meta:rid
             or pico ruleset_added where rid == meta:rid
    fired {
      ent:refs := {};
      ent:txts := {};
    }
  }
  rule bofm_verse {
    select when bofm verse
    foreach event:attrs() setting(txt,ref)
    fired {
      ent:refs{time:now()} := ref;
      ent:txts{ref} := txt;
    }
  }
}
