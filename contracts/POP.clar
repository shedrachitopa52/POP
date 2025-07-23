;; ------------------------------------------------------------
;; Contract: Proof of Presence (PoP)
;; Description: Users check in at real-world locations and earn NFTs as proof.
;; Author: Thankgod Isaac
;; Blockchain: Stacks (Clarity)
;; License: MIT
;; ------------------------------------------------------------

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-LOCATION-NOT-FOUND (err u101))
(define-constant ERR-LOCATION-INACTIVE (err u102))
(define-constant ERR-ALREADY-CHECKED-IN (err u103))
(define-constant ERR-TOKEN-NOT-FOUND (err u404))
(define-constant ERR-NOT-TOKEN-OWNER (err u403))

;; NFT Token Name
(define-non-fungible-token pop-badge uint)

;; ---------------------------
;; Data Structures & Storage
;; ---------------------------

(define-data-var admin principal tx-sender)

(define-map locations
  uint
  {
    name: (string-ascii 40),
    active: bool,
    reward-nft: bool,
    reward-stx: (optional uint)
  }
)

(define-map checkins
  {user: principal, location-id: uint}
  bool
)

(define-data-var token-counter uint u0)

;; ---------------------------
;; NFT Metadata (PoP Badge)
;; ---------------------------

(define-map token-uri
  uint
  (string-utf8 256)
)

;; ---------------------------
;; Utility Functions
;; ---------------------------

(define-read-only (is-admin (sender principal))
  (is-eq sender (var-get admin))
)

(define-read-only (has-checked-in (user principal) (location-id uint))
  (default-to false (map-get? checkins {user: user, location-id: location-id}))
)

(define-read-only (get-location (location-id uint))
  (map-get? locations location-id)
)

(define-read-only (get-admin)
  (var-get admin)
)

;; ---------------------------
;; Admin Functions
;; ---------------------------

(define-public (add-location (location-id uint) (name (string-ascii 40)) (reward-nft bool) (reward-stx (optional uint)))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (map-set locations location-id
      {
        name: name,
        active: true,
        reward-nft: reward-nft,
        reward-stx: reward-stx
      }
    )
    (ok true)
  )
)

(define-public (deactivate-location (location-id uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (let ((loc (map-get? locations location-id)))
      (match loc
        location-data
          (begin
            (map-set locations location-id
              (merge location-data {active: false}))
            (ok true)
          )
        ERR-LOCATION-NOT-FOUND
      )
    )
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)

;; ---------------------------
;; NFT Implementation (SIP-009)
;; ---------------------------

(define-private (mint-pop-nft (recipient principal))
  (let (
    (next-id (+ (var-get token-counter) u1))
  )
    (var-set token-counter next-id)
    (map-set token-uri next-id u"https://example.com/pop-badge")
    (try! (nft-mint? pop-badge next-id recipient))
    (ok next-id)
  )
)

(define-public (get-token-uri (id uint))
  (ok (map-get? token-uri id))
)

(define-public (get-owner (id uint))
  (ok (nft-get-owner? pop-badge id))
)

(define-public (get-last-token-id)
  (ok (var-get token-counter))
)

(define-public (transfer (id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq sender tx-sender) ERR-NOT-TOKEN-OWNER)
    (try! (nft-transfer? pop-badge id sender recipient))
    (ok true)
  )
)

;; ---------------------------
;; User Check-In Function
;; ---------------------------

(define-public (check-in (location-id uint))
  (let (
    (loc (map-get? locations location-id))
  )
    (match loc location-data
      (begin
        (asserts! (get active location-data) ERR-LOCATION-INACTIVE)
        (asserts! (not (has-checked-in tx-sender location-id)) ERR-ALREADY-CHECKED-IN)
        
        ;; Save check-in
        (map-set checkins {user: tx-sender, location-id: location-id} true)

        ;; Handle STX reward if any
        (match (get reward-stx location-data)
          amt (try! (stx-transfer? amt (var-get admin) tx-sender))
          true
        )

        ;; Handle NFT reward
        (if (get reward-nft location-data)
          (begin
            (try! (mint-pop-nft tx-sender))
            (ok true)
          )
          (ok true)
        )
      )
      ERR-LOCATION-NOT-FOUND
    )
  )
)

;; ---------------------------
;; Contract STX Treasury
;; ---------------------------

(define-public (deposit-treasury)
  (ok true)
)

(define-public (withdraw-stx (amount uint) (to principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (try! (stx-transfer? amount tx-sender to))
    (ok true)
  )
)

