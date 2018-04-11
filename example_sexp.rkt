#lang spicy

(define (foldl f x lst)
  (match lst
         ('() x)
         ((cons a l) (foldl f (f a x) l))))

(define (foldr f x lst)
  (match lst
         ('() x)
         ((cons a l) (f a (foldr f x l)))))

(define reverse
  (foldl cons empty))

(define (append a b)
  (foldr cons b a))

(define (append* . lsts)
  (foldr append empty lsts))

(define sum
  (foldl + 0))

(define product
  (foldl * 1))

(define (map f)
  (foldr (compose cons f) empty))

(module+ main
  (define a '(1 2))
  (define b '(3 4))
  (define c '(5 6 7))
  (define (f x) (* x x))
  (append a b)
  (reverse c)
  (sum a)
  (product b)
  (product (append a b))
  (append* a b c)
  (map f c))
