ruleset bofm.test {
  meta {
    use module bofm.data alias bofm
    shares __testing, tests
  }
  global {
    __testing = { "queries": [ { "name": "__testing" }
                             ],
                  "events": [ { "domain": "bofm", "type": "test", "attrs": [] } ] }
    equal = function(expr,expected) {
      expr == expected
    }
    ref1 = "1 Nephi 7:3"
    ref2 = "1 Nephi 10:1"
    ref3 = "Jacob 5:8"
    ref4 = "Jacob 5:77"
    ref5 = "Alma 63:5"
  }
  rule bofm_test {
    select when bofm test
    pre {
      tests = [
        equal(bofm:ref_cmp(ref1,ref2),-1),
        equal(bofm:ref_cmp(ref2,ref3),-1),
        equal(bofm:ref_cmp(ref3,ref4),-1),
        equal(bofm:ref_cmp(ref4,ref5),-1) ];
    }
    send_directive("results",{"tests":tests});
  }
}
