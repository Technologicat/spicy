#lang sweet-exp racket

define foldl(f x lst)
  match lst
    '() x
    (cons a l) (foldl f (f a x) l)

define foldr(f x lst)
  match lst
    '() x
    (cons a l) (f a (foldr f x l))

define reverse
  curry foldl cons empty

define append(a b)
  foldr cons b a

define append*(. lsts)
  foldr append empty lsts

;; adaptors to fit an arity-1 function into an arity-2 compose chain
define ->1(f) (λ (a b) (values (f a) b))
define ->2(f) (λ (a b) (values a (f b)))

define map(f lst)     ; apply immediately
  foldr (compose cons (->1 f)) empty lst

define map2(f)        ; return an "f-mapper"
  curry foldr (compose cons (->1 f)) empty

define map3(f . lst)  ; return an f-mapper if no more args, else apply immediately.
  apply curry foldr (compose cons (->1 f)) empty lst

define sum
  curry foldl + 0

define product
  curry foldl * 1

module+ main
  define a '(1 2)
  define b '(3 4)
  define c '(5 6 7)
  define f(x) {x * x}
  append a b
  reverse c
  sum a
  product b
  product (append a b)
  append* a b c
  map f c
  (map2 f) c
  map3 f c
  (map3 f) c
