Requires a module which is capable of produce, on demand, a random verse, as a map 
whose key is the reference and whose value is the text of the verse

An example of such a module

```ruleset bofm.random {
  meta {
    provides verse
  }
  global {
    verse = function() {
      { "1 Nephi 7:3": "I will go and do..." }
    }
  }
}```
