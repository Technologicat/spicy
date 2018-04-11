#lang sweet-exp racket

;; For #lang spicy, we need to supply a reader.
;;
;; We don't want to do anything at this level,
;; so we just borrow Racket's default reader.
module reader syntax/module-reader
  spicy/expander

;; For #lang sweet-exp spicy, #lang s-exp spicy,
;; this needs to work as a module language.
require spicy/expander
provide (all-from-out spicy/expander)

;; Useful docs:
;;   https://beautifulracket.com/stacker/the-expander.html
;;   https://beautifulracket.com/bf/packaging-our-language.html
;;   https://docs.racket-lang.org/guide/language-collection.html
;;   https://docs.racket-lang.org/syntax/reader-helpers.html#%28mod-path._syntax%2Fmodule-reader%29
