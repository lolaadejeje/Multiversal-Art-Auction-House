;; Quantum Random Number Generator Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))

;; Data Variables
(define-data-var last-random-number uint u0)
(define-data-var last-update-block uint u0)

;; Public Functions
(define-public (update-random-number (new-number uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set last-random-number new-number)
        (var-set last-update-block block-height)
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-random-number)
    (var-get last-random-number)
)

(define-read-only (get-last-update-block)
    (var-get last-update-block)
)

;; Helper function to generate a pseudo-random number (for demonstration purposes)
(define-read-only (generate-pseudo-random (seed uint))
    (mod (+ (* (var-get last-random-number) seed) block-height) u1000000)
)
