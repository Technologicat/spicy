#lang sweet-exp racket
;;; with-curry, splicing-with-curry: local spicification.
;;;
;;; For applying spicy in short, controlled bursts.

require syntax/parse/define
require racket/splicing

require (only-in spicy/expander [#%app spicy-app]
                                [curry spicy-curry]
                                [compose spicy-compose])

provide with-curry splicing-with-curry

require (for-meta 2 racket/base)
require (for-syntax syntax/parse/define)
begin-for-syntax
  define-syntax-parser make-with-curry-form
    [_ name the-let-stx]
      with-syntax ([ooo (quote-syntax ...)]
                   [ooo+ (quote-syntax ...+)])
        syntax
          let ([name-sym (syntax->datum #'name)])
            syntax-parser
              [_ body ooo+]
                with-syntax ([#%app (datum->syntax this-syntax '#%app)]
                             [curry (datum->syntax this-syntax 'curry)]
                             [compose (datum->syntax this-syntax 'compose)])
                  syntax
                    the-let-stx ([#%app (make-rename-transformer #'spicy-app)]
                                 [curry (make-rename-transformer #'spicy-curry)]
                                 [compose (make-rename-transformer #'spicy-compose)])
                      body
                      ooo
              [_]
                raise-syntax-error name-sym "expected at least one body"

define-syntax with-curry (make-with-curry-form with-curry let-syntax)
define-syntax splicing-with-curry (make-with-curry-form splicing-with-curry splicing-let-syntax)

module+ main
  ;; block with local spicification
  with-curry
    define mymap-local(f)
      foldr (compose cons f) empty
    mymap-local
      λ (x) {x * x}
      '(1 2 3)
  ;
  ;; block that splices spiced definitions into surrounding context
  splicing-with-curry
    define mymap(f)
      foldr (compose cons f) empty
  ;; now autocurry is off
  (mymap (λ (x) {x * x}))
    '(1 2 3)
