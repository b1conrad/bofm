ruleset bofm.consumer {
  meta {
    use module bofm.data alias bofm
    shares __testing, refs, refs_page, txt_page
  }
  global {
    __testing =
    { "queries": [ { "name": "__testing" }
                 , { "name": "refs" }
                 , { "name": "refs_page" }
                 , { "name": "txt_page", "args": [ "ref" ] }
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
      <<<form action="txt_page.html">
#{refs_select()}  <input type="submit" value="txt">
</form>
>>
    }
    refs_intro = function() {
      timestamps = ent:refs.keys();
      <<<p>
Collected between #{timestamps.head()}
and #{timestamps[timestamps.length()-1]}
(#{timestamps.length().as("String")})
</p>
>>
    }
    refs_page = function() {
      <<<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Collected verses</title>
</head>
<body>
#{refs_intro()}#{refs_form()}</body>
</html>
>>
    }
    txt_page = function(ref) {
      <<<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Collected verses</title>
</head>
<body>
<dl style="width:400px">
  <dt>#{ref}</dt>
  <dd>#{ent:txts{ref}}</dd>
</dl>
</body>
</html>
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
    foreach event:attrs setting(txt,ref)
    fired {
      ent:refs{time:now()} := ref;
      ent:txts{ref} := txt;
    }
  }
}
