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

define-syntax-parser with-curry
  [_ body ...+]
    with-syntax ([#%app (datum->syntax this-syntax '#%app)]
                 [curry (datum->syntax this-syntax 'curry)]
                 [compose (datum->syntax this-syntax 'compose)])
      syntax
        let-syntax ([#%app (make-rename-transformer #'spicy-app)]
                    [curry (make-rename-transformer #'spicy-curry)]
                    [compose (make-rename-transformer #'spicy-compose)])
          body
          ...
  [_]
    raise-syntax-error 'with-curry "needs at least one body"

define-syntax-parser splicing-with-curry
  [_ body ...+]
    with-syntax ([#%app (datum->syntax this-syntax '#%app)]
                 [curry (datum->syntax this-syntax 'curry)]
                 [compose (datum->syntax this-syntax 'compose)])
      syntax
        splicing-let-syntax ([#%app (make-rename-transformer #'spicy-app)]
                             [curry (make-rename-transformer #'spicy-curry)]
                             [compose (make-rename-transformer #'spicy-compose)])
          body
          ...
  [_]
    raise-syntax-error 'splicing-with-curry "needs at least one body"

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
