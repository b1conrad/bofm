ruleset bofm.data {
  meta {
    provides ref_parts, ref_cmp, book_names, book_chapters
  }
  global {
    book_names = [
      "1 Nephi", "2 Nephi", "Jacob", "Enos", "Jarom",
      "Omni", "Words of Mormon", "Mosiah", "Alma", "Helaman",
      "3 Nephi", "4 Nephi", "Mormon", "Ether", "Moroni"
    ]
    ref_parts = function(ref) { ref.extract(re#(.+) (\d+):(\d+)#) }
    num_cmp = function(a,b) { a.as("Number") <=> b.as("Number") }
    ref_cmp = function(ref_1,ref_2) {
      r1 = ref_parts(ref_1);
      r2 = ref_parts(ref_2);
      verse_cmp = function() { num_cmp(r1[2],r2[2]) };
      chapter_cmp = function() {
        ans = num_cmp(r1[1],r2[1]); ans => ans | verse_cmp() };
      book_cmp = book_names.index(r1[0]) <=> book_names.index(r2[0]);
      book_cmp => book_cmp | chapter_cmp()
    }
    chapters = [ 22, 33, 7, 1, 1, 1, 1, 29, 63, 16, 30, 1, 9, 15, 10 ]
    book_chapters = function(book_name) {
      book_number = book_names.index(book_name);
      book_number >= 0 => chapters[book_number] | 0
    }
  }
}
