;; Multiversal Artwork Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-invalid-parameters (err u102))

;; NFT Definition
(define-non-fungible-token multiversal-artwork uint)

;; Data Variables
(define-data-var last-token-id uint u0)
(define-map token-metadata uint {
    artist: principal,
    title: (string-ascii 100),
    description: (string-utf8 1000),
    universe-id: uint,
    quantum-signature: (buff 32),
    creation-block: uint
})

;; Private Functions
(define-private (is-owner (token-id uint))
    (is-eq tx-sender (unwrap! (nft-get-owner? multiversal-artwork token-id) false))
)

;; Public Functions
(define-public (create-artwork (title (string-ascii 100)) (description (string-utf8 1000)) (universe-id uint) (quantum-signature (buff 32)))
    (let
        (
            (token-id (+ (var-get last-token-id) u1))
        )
        (try! (nft-mint? multiversal-artwork token-id tx-sender))
        (map-set token-metadata token-id {
            artist: tx-sender,
            title: title,
            description: description,
            universe-id: universe-id,
            quantum-signature: quantum-signature,
            creation-block: block-height
        })
        (var-set last-token-id token-id)
        (ok token-id)
    )
)

(define-public (transfer (token-id uint) (recipient principal))
    (begin
        (asserts! (is-owner token-id) err-not-token-owner)
        (try! (nft-transfer? multiversal-artwork token-id tx-sender recipient))
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-token-metadata (token-id uint))
    (map-get? token-metadata token-id)
)

(define-read-only (get-last-token-id)
    (var-get last-token-id)
)
