#lang sweet-exp spicy

;; A tour of the features of spicy.

module+ main
  ; kwargs can be given in the first call, as usual:
  define foo(#:a a b c)
    displayln (format "~a ~a ~a" a b c)
  foo #:a 1 2 3
  (foo #:a 1 2) 3
  (foo #:a 1) 2 3
  ;
  define f(x) {x * x}
  define g(x y) {{2 * x} + {3 * y}}
  f(4)     ; single-arg functions behave as usual
  g(2 5)   ; call with several arguments - behaves like usual
  g 2 5    ; also a call with several arguments (sweet-exp)
  g(2)(5)  ; auto-curried - works, too.
  ;
  ;; any extra args > max arity are passed through on the right:
  let-values ([(a b) g(2 5 8)])
    displayln a  ; result of g(2 5)
    displayln b  ; 8
  ;
  ;; The automatic passthrough can be utilized for Haskell-y idioms like this:
  ;;   - foldr calls proc(elt acc), so proc must accept 2 arguments
  ;;   - but f doesn't; its signature is 1->1. The extra arg is passed through on the right.
  ;;   - signature of cons is 2->1
  ;;   - foldr uses the output of proc (which is here cons) as the new value of acc
  define mymap1(f lst)
    foldr (compose cons f) empty lst
  mymap1 f '(1 2 3)
  ;
  ;; Point-free style, omitting the lst:
  define mymap2(f)
    foldr (compose cons f) empty
  (mymap2 f) '(1 2 3)  ; (mymap2 f) gets the "f-mapper"
  ;
  ;; In the customized curry function in spicy, a curried proc intermediate result
  ;; means that the procedure is applied to the remaining arguments, so this works too.
  ;;
  ;; The difference to the "g 2 5" example is that here, the arity of mymap2 is just 1.
  ;;   - Hence, (mymap2 f) is called first; the result is a curried procedure
  ;;   - This procedure is applied to the remaining argument.
  ;;
  mymap2 f '(1 2 3)
  ;
  define thunk()  ; 0-arity function behaves as usual
    displayln "hello"
  thunk()
  ;
  define thunk-with-values()  ; 0-arity with multiple return values
    values 'a 'b 'c
  thunk-with-values()
  ;
  ;; Optional args
  define f-with-optional-arg([x 42])
    displayln x
  procedure-arity f-with-optional-arg  ; '(0 1)
  f-with-optional-arg(23)
  f-with-optional-arg()  ; 0 is a valid arity for this proc; calls immediately
  ;
  ;; On the other hand:
  + 1             ; computes result since 1 is a valid arity - can't auto-curry
  define add-one
    curry + 1     ; curry manually to disable auto-curry
  add-one 41
  ;
  ;; Another way to work around: operation with a fixed max-arity:
  define add(a b) (+ a b)
  define add1
    add 1
  ;
  add1 41
