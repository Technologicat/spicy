# spicy: Automatic currying for Racket

```racket
#lang spicy

(define (map f)
  (foldr (compose cons f) empty))

(module+ main
  (define a '(1 2 3))
  (define (f x) (* x x))
  (map f a))
```

Compare **not** spicy:

```racket
#lang racket

(define (->1 f) (λ (a b) (values (f a) b)))
(define (map f . args)
  (apply curry foldr (compose cons (->1 f)) empty args))

(module+ main
  (define a '(1 2 3))
  (define (f x) (* x x))
  (map f a))
```

For fewer parentheses, combine spicy with [sweet-exp](https://docs.racket-lang.org/sweet/):

```racket
#lang sweet-exp spicy

define map(f)
  foldr (compose cons f) empty

module+ main
  define a '(1 2 3)
  define (f x) (* x x)
  map f a
```

To spice locally, `spicy/sauce`:

```racket
#lang sweet-exp racket

require spicy/sauce

module+ main
  with-curry
    define mymap-local(f)
      foldr (compose cons f) empty
    mymap-local
      λ (x) {x * x}
      '(1 2 3)
  ;
  splicing-with-curry
    define mymap(f)
      foldr (compose cons f) empty
  ;; now autocurry is off
  (mymap (λ (x) {x * x}))
    '(1 2 3)
```

## Examples

Some more simple examples, based on those in [Hughes (1984): Why functional programming matters](http://www.cse.chalmers.se/~rjmh/Papers/whyfp.pdf) and racketified.

 - [Spicy, with traditional s-expressions](example_sexp.rkt)
 - [Spicy, with sweet expressions](example_sweet.rkt)
 - [Not spicy](example_nonspicy.rkt)

For details, take the [tour](tour.rkt).

## Human-readable rules

 - All function applications are curried. Currying is applied from the left.
 - Keyword arguments can be passed in the initial call, just like when currying manually in Racket.
 - Any arguments over max-arity are *passed through on the right*, by constructing a multiple-values object.
   - This makes the above example possible, although the arities of `f` and `cons` are different.
 - If the application also returns a multiple-values, the remaining arguments (if any) are appended into it.
 - If the application produces only one value, which is another curried procedure, it is applied to the remaining arguments.
   - See the [tour](tour.rkt) for where this is useful.
 - The auto-curried procedure immediately switches to the mode where *any acceptable arity* triggers a call.
   - In contrast, currying manually in Racket always curries at least once (if a higher arity exists).
   - Hence some variadic functions (notably e.g. `+`, `*`) cannot be auto-curried in `spicy`, since they accept any arity ≥ 0.
   - Curry manually to revert to Racket's usual processing: `+ 1` → 1, but `curry + 1` → `#<procedure:curried>`.
     - It will still use the customized `curry` function from `spicy`, but skips the automatic mode switching.

## Installation

 - Copy the files anywhere you want.
 - Open a terminal in the `spicy/` subfolder.
 - `raco pkg install`

To uninstall, `raco pkg remove spicy`.

## How it works

Essentially, a custom `#%app` macro to rewrite function applications at compile time, a customized `curry`, and [four lines of code](spicy/main.rkt) to package that as a language that borrows everything else from Racket.

Also, the [`compose`](https://docs.racket-lang.org/reference/procedures.html#%28def._%28%28lib._racket%2Fprivate%2Flist..rkt%29._compose%29%29) function is overridden by a curry-aware version, which spices its arguments.

## Disclaimer

Primarily meant for teaching purposes. Tested only on toy examples.

Not completely seamless, and cannot be. Automatic currying and variadic functions do not play well together; also, dynamic typing implies that the system won't notice if you miss an argument somewhere - which may make your code hard to debug. For discussion on the topic, see e.g. [here](https://stackoverflow.com/questions/11218905/is-it-possible-to-implement-auto-currying-to-the-lisp-family-languages), [here](http://paqmind.com/blog/currying-in-lisp/) and [here](https://stackoverflow.com/questions/31373507/rich-hickeys-reason-for-not-auto-currying-clojure-functions).

## License

[GNU LGPL 3.0](https://www.gnu.org/licenses/lgpl-3.0.html).

Contains a customized version of Racket's [`curry`](https://docs.racket-lang.org/reference/procedures.html#%28def._%28%28lib._racket%2Ffunction..rkt%29._curry%29%29), which is [used under](https://download.racket-lang.org/license.html) GNU LGPL 3.0.

## Dependencies

 - [sweet-exp](https://docs.racket-lang.org/sweet/) is currently used by the implementation in [spicy/expander.rkt](spicy/expander.rkt).

