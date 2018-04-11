#lang sweet-exp racket

;; An experiment in automatic currying for Racket.
;;
;; In general, this sort of thing cannot be made to play well with variadic functions,
;; so this is mainly useful for teaching purposes.
;;
;; See e.g.
;;   https://stackoverflow.com/questions/11218905/is-it-possible-to-implement-auto-currying
;;      -to-the-lisp-family-languages
;;   http://paqmind.com/blog/currying-in-lisp/
;;
;; Inspiration:
;;   http://www.cse.chalmers.se/~rjmh/Papers/whyfp.html
;;
;; This version allows kwargs in the first call, like Racket's curry.

provide
  all-from-out 'spicy  ; for use from other modules

module spicy racket
  provide
    except-out
      all-from-out racket
      #%app
    rename-out
      #%spicy-app #%app
    curry
    ; TODO: curryr
    compose
  ;
  require
    rename-in
      racket
      [compose compose-impl]
  ;
  require syntax/parse/define
  require "values-listify.rkt"
  ;
  ;; Things such as (displayln 'foo) work because we call the curried proc one extra time.
  ;; The arity of displayln includes 1, so the curried version gets called immediately
  ;; even if there is just one argument.
  ;;
  ;; This implies that if the first set of args already has an arity that the function accepts,
  ;; then it is not possible to add more args by currying. For some variadic functions (esp. + *),
  ;; this means that all args should be passed in one call, in the usual rackety manner.
  ;;
  ;; This behavior slightly differs from Racket's curry:
  ;;
  ;;   - Racket's curry treats the first call to the curried proc specially: only n = max-arity
  ;;     arguments trigger a call to the original procedure. But during second and further calls,
  ;;     *any acceptable arity* triggers a call.
  ;;
  ;;   - Autocurry always enters the second operation mode immediately: any acceptable arity
  ;;     will trigger a call. This makes procedures with optional args behave more consistently.
  ;;
  ;;     (Consider especially the case of just one arg, which is optional: how to tell curry to use
  ;;      the default value? Racket's curry just returns a curried procedure, because max-arity was
  ;;      not reached yet; the returned procedure must be called again to actually trigger a call
  ;;      into the original procedure. The second call triggers, because the mode has changed.)
  ;;
  define-syntax-parser #%spicy-app
    #:literals (curry)
    (_ curry proc maybe-args ...)  ; allow explicit curry() without spicing it
      #'(#%app curry proc maybe-args ...)
    ;
    ;; no arguments
    ;; - we need an extra call here, because curry treats the arity-0 case differently.
    (_ proc)
      #'(let ([result (values->list ((spice proc)))])
           (call-if-curried result))
    ;
    ;; with arguments - reducible cases
    ;
    ;; move positional terms from the front to after the first set of keywords
    [_ proc
     positional-stuff:expr ...+
     (~and (~seq (~seq k:keyword e:expr) ...+)
           (~seq keyword-stuff ...+))
     maybe-tail ...]
       #'(#%spicy-app keyword-stuff ... positional-stuff ... maybe-tail ...)
    ;
    ;; move positional terms from between two sets of keywords to after the second set
    [_ proc
     (~and (~seq (~seq k1:keyword e1:expr) ...+)
           (~seq keyword-stuff1 ...+))
     positional-stuff:expr ...+
     (~and (~seq (~seq k2:keyword e2:expr) ...+)
           (~seq keyword-stuff2 ...+))
     maybe-tail ...]
       #'(#%spicy-app keyword-stuff1 ... keyword-stuff2 ... positional-stuff ... maybe-tail ...)
    ;
    ;; with arguments - base cases
    ;
    ;; with keywords (now always at the front)
    [_ proc
     (~and (~seq (~seq k:keyword e:expr) ...+)
           (~seq keyword-stuff ...+))
     positional-stuff:expr ...]
      #'(let ([result (values->list (apply spice proc positional-stuff ... empty keyword-stuff ...))])
           (call-if-curried result))
    ;
    ;; positional only
    [_ proc positional-stuff:expr ...]
      #'(let ([result (values->list (apply spice proc positional-stuff ... empty))])
           (call-if-curried result))
  ;
  ;; Helper function
  define call-if-curried(proc-or-results)
    define maybe-curried (car proc-or-results)
    cond
      eq?(object-name(maybe-curried) 'curried)  ; TODO: more robust way to detect?
        ;(displayln "DEBUG: calling curried proc")
        (maybe-curried)  ; Change the operation mode of the curried procedure
                         ; to call as soon as any acceptable arity is provided.
      else
        list->values proc-or-results  ; Original proc already called, just return results.
  ;
  ;; Curry proc if not yet curried, else call the curried proc.
  ;;
  ;; spice(proc arg0 ... #:<kw> kv ...)
  ;;
  ;; where <kw> is any keyword.
  ;;
  ;; All arguments except proc passed through to curry (or to the curried proc, as appropriate).
  ;;
  ;; If proc is not yet curried, this will "freeze in" the base set of arguments, allowing also
  ;; kwargs to be passed.
  ;;
  define spice
    make-keyword-procedure
      λ (kw kv proc . args)
        ;displayln (format "DEBUG: spice (with kws): ~a ~a ~a ~a" object-name(proc) args kw kv)
        cond
          (not (eq? object-name(proc) 'curried))  ; TODO: more robust way to detect?
            ;displayln (format "DEBUG: currying (with kws): ~a" object-name(proc))
            keyword-apply curry kw kv proc args
          else
            keyword-apply proc kw kv args
      λ (proc . args)
        ;displayln (format "DEBUG: spice: ~a ~a" object-name(proc) args)
        cond
          (not (eq? object-name(proc) 'curried))  ; TODO: more robust way to detect?
            ;displayln (format "DEBUG: currying ~a" object-name(proc))
            apply curry proc args
          else
            apply proc args
  ;
  ;; Most higher-order functions we don't need to touch, but those that combine user-given functions
  ;; (such as compose() here) may need to spice() their arguments.
  ;;
  ;; Those are not in operator position, and hence #%spicy-app won't automatically apply to them.
  ;;
  define compose(. args)
    apply compose-impl (map spice args)
  ;
  ;; Curry, modified to support more than max-arity args.
  ;;
  ;; - When curry() is called with just proc (no args for it), it just sets up currying,
  ;;   and returns the curried procedure.
  ;;
  ;;   - The first call into the curried procedure tests for n >= max-arity, and if so,
  ;;     calls the original proc immediately. (For n > max-arity, see details below.)
  ;;
  ;;     NOTE: if max-arity is 0, this will already trigger a call into the original procedure!
  ;;
  ;;   - But if n < max-arity, that call just changes the operation mode of the curried procedure.
  ;;     After the mode change, *any acceptable arity* (not just max-arity) will trigger a call
  ;;     to the original procedure.
  ;;
  ;; - If curry() is called with proc and args, those args are used to immediately perform
  ;;   the first call into the curried procedure. This is also the only way to pass in kwargs.
  ;;
  ;; If the curried procedure is called with n > max-arity arguments:
  ;;
  ;; - The arglist is split into two parts.
  ;; - The original procedure is called with the first max-arity args.
  ;; - What happens next depends on the return value:
  ;;   - If it is a single value, which contains another curried procedure,
  ;;     that procedure is applied to the remaining arguments.
  ;;   - Otherwise any extra args are passed through on the right.
  ;;     The return value(s) and the extra args are combined into a single multiple-values object.
  ;;
  ;; TODO: generalize passthrough to work correctly with curryr
  ;;
  ;; Based on make-curry in Racket 6.10.1 [3m], collects/racket/function.rkt
  ;;
  ;; The implementation is deliberately kept as close to the original as possible, to make this
  ;; (at least nearly) a drop-in replacement for Racket's curry. The special-casing for max-arity 0
  ;; is done in #%spicy-app instead.
  ;
  (define (make-curry right?)
    ;; The real code is here
    (define (curry* f args kws kvs)
      (unless (procedure? f)
        (raise-argument-error (if right? 'curryr 'curry) "procedure?" f))
      (let* ([arity (procedure-arity f)]
             [max-arity (cond [(integer? arity) arity]
                              [(arity-at-least? arity) #f]
                              [(ormap arity-at-least? arity) #f]
                              [else (apply max arity)])]
             [n (length args)])
        ;(displayln
        ;  (format "DEBUG: curry: ~a: arity ~a, max ~a, n ~a, args ~a" f arity max-arity n args))
        (define (call-with-extra-args args)
           (let-values ([(now-args later-args) (split-at args max-arity)])
               ;(displayln (format "DEBUG [>-max-arity CALL]: ~a, now: ~a, later: ~a"
               ;                   f now-args later-args))
               (define now-result (values->list (if (null? kws)
                                                    (apply f now-args)
                                                    (keyword-apply f kws kvs now-args))))
               ;; If the now-result is a single value, which contains a curried proc,
               ;; call it with the extra args, to better support point-free style.
               (define g (car now-result))
               (cond
                 ([and (empty? (cdr now-result))
                       (procedure? g)
                       (eq? (object-name g) 'curried)]
                   (apply g later-args))
                 ;; Otherwise pass any extra args through on the right.
                 (else
                   (list->values (append now-result later-args))))))
        (define (loop args n)
          ;(displayln
          ;   (format "DEBUG [later call]: ~a: arity ~a, max ~a, n ~a, args ~a"
          ;           object-name(f) arity max-arity n args))
          (cond
            ;; We need the #t because f may have already accepted keyword arguments,
            ;; which still show in its arity, although the curried procedure does not
            ;; accept any more of them.
            ([procedure-arity-includes? f n #t]
             ;(displayln (format "DEBUG [arity-includes CALL]: ~a" f))
             (if (null? kws) (apply f args) (keyword-apply f kws kvs args)))
            ([and max-arity {n > max-arity}]  ; original just raises an error in this case
              (call-with-extra-args args))
            (else
              (letrec [(curried
                        (case-lambda
                          [() curried] ; return itself on zero arguments [loop not called!]
                          [more (loop (if right?
                                          (append more args) (append args more))
                                      (+ n (length more)))]))]
                curried))))
        ;; take at least one step if we can continue (there is a higher arity)
        ;(displayln
        ;   (format "DEBUG [first call]: ~a: arity ~a, max ~a, n ~a, args ~a"
        ;           object-name(f) arity max-arity n args))
        (cond
          ; handle >= max-arity args, when given in the first call (before loop() is called).
          ([equal? n max-arity]
            ;(displayln (format "DEBUG [exact-arity CALL]: ~a" f))
            (if (null? kws) (apply f args) (keyword-apply f kws kvs args)))
          ([and max-arity {n > max-arity}]
            (call-with-extra-args args))
          (else
            (letrec ([curried
                      (lambda more
                        (let ([args (if right?
                                        (append more args) (append args more))])
                          (loop args (+ n (length more)))))])
              ;(displayln (format "DEBUG: letrec: ~a, args: ~a" f args))
              curried)))))
    ;; curry is itself curried -- if we get args then they're the first step
    (define curry
      (case-lambda [(f) (define (curried . args) (curry* f args '() '()))
                        curried]
                   [(f . args) (curry* f args '() '())]))
    (make-keyword-procedure (lambda (kws kvs f . args) (curry* f args kws kvs))
                            curry))
  ;
  (define curry  (make-curry #f))
  ;(define curryr (make-curry #t))  ; TODO: curryr (passthrough on the left?)

;; load it
require 'spicy
