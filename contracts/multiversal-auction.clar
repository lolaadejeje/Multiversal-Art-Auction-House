;; Multiversal Auction Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-invalid-parameters (err u102))
(define-constant err-auction-not-active (err u103))
(define-constant err-bid-too-low (err u104))

;; SIP-010 Token Trait
(use-trait sip-010-token .sip-010-trait.sip-010-trait)

;; Data Variables
(define-data-var last-auction-id uint u0)
(define-map auctions uint {
    seller: principal,
    token-id: uint,
    start-block: uint,
    end-block: uint,
    reserve-price: uint,
    current-bid: uint,
    current-bidder: (optional principal),
    status: (string-ascii 20)
})

;; Public Functions
(define-public (create-auction (token-id uint) (reserve-price uint) (duration uint) (payment-token <sip-010-token>))
    (let
        (
            (auction-id (+ (var-get last-auction-id) u1))
        )
        (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? .multiversal-artwork token-id) err-not-token-owner)) err-not-token-owner)
        (asserts! (> duration u0) err-invalid-parameters)
        (try! (contract-call? .multiversal-artwork transfer token-id (as-contract tx-sender)))
        (map-set auctions auction-id {
            seller: tx-sender,
            token-id: token-id,
            start-block: block-height,
            end-block: (+ block-height duration),
            reserve-price: reserve-price,
            current-bid: u0,
            current-bidder: none,
            status: "active"
        })
        (var-set last-auction-id auction-id)
        (ok auction-id)
    )
)

(define-public (place-bid (auction-id uint) (bid-amount uint) (payment-token <sip-010-token>))
    (let
        (
            (auction (unwrap! (map-get? auctions auction-id) err-invalid-parameters))
            (current-bid (get current-bid auction))
        )
        (asserts! (is-eq (get status auction) "active") err-auction-not-active)
        (asserts! (<= block-height (get end-block auction)) err-auction-not-active)
        (asserts! (> bid-amount current-bid) err-bid-too-low)
        (asserts! (>= bid-amount (get reserve-price auction)) err-bid-too-low)
        (match (get current-bidder auction)
            prev-bidder (try! (as-contract (contract-call? payment-token transfer bid-amount tx-sender prev-bidder)))
            true
        )
        (try! (contract-call? payment-token transfer bid-amount tx-sender (as-contract tx-sender)))
        (map-set auctions auction-id
            (merge auction {
                current-bid: bid-amount,
                current-bidder: (some tx-sender)
            })
        )
        (ok true)
    )
)

(define-public (end-auction (auction-id uint))
    (let
        (
            (auction (unwrap! (map-get? auctions auction-id) err-invalid-parameters))
        )
        (asserts! (>= block-height (get end-block auction)) err-auction-not-active)
        (asserts! (is-eq (get status auction) "active") err-auction-not-active)
        (match (get current-bidder auction)
            winner (begin
                (try! (as-contract (contract-call? .multiversal-artwork transfer (get token-id auction) winner)))
                (try! (as-contract (contract-call? .sip-010-trait transfer (get current-bid auction) (get seller auction))))
            )
            (begin
                (try! (as-contract (contract-call? .multiversal-artwork transfer (get token-id auction) (get seller auction))))
            )
        )
        (map-set auctions auction-id
            (merge auction {
                status: "ended"
            })
        )
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-auction (auction-id uint))
    (map-get? auctions auction-id)
)

(define-read-only (get-last-auction-id)
    (var-get last-auction-id)
)
