;; SIP-010 Fungible Token Standard
(define-trait sip010-ft-standard
  (
    (transfer (uint principal principal) (response bool uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-decimals () (response uint uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-name () (response (string-ascii 32) uint))
  )
)

;; Token constants
(define-constant token-name "GreenCredit")
(define-constant token-symbol "GCR")
(define-constant decimals u0)

;; Error constants
(define-constant err-unauthorized (err u401))
(define-constant err-insufficient-balance (err u402))
(define-constant err-invalid-sender (err u403))

;; Data variables
(define-data-var total-supply uint u0)
(define-data-var admin principal tx-sender)

;; Data maps
(define-map balances { owner: principal } { amount: uint })
(define-map retired { owner: principal } { amount: uint })

;; Admin functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-unauthorized)
    (var-set admin new-admin)
    (ok true)
  )
)

;; Mint function
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-unauthorized)
    (var-set total-supply (+ (var-get total-supply) amount))
    (let ((current-balance (default-to u0 (get amount (map-get? balances { owner: recipient })))))
      (map-set balances { owner: recipient } { amount: (+ current-balance amount) })
    )
    (ok true)
  )
)

;; Transfer function
(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-invalid-sender)
    (let ((sender-balance (default-to u0 (get amount (map-get? balances { owner: sender })))))
      (asserts! (>= sender-balance amount) err-insufficient-balance)
      (map-set balances { owner: sender } { amount: (- sender-balance amount) })
      (let ((recipient-balance (default-to u0 (get amount (map-get? balances { owner: recipient })))))
        (map-set balances { owner: recipient } { amount: (+ recipient-balance amount) })
      )
      (ok true)
    )
  )
)

;; Retire function (burn tokens)
(define-public (retire (amount uint))
  (let ((user-balance (default-to u0 (get amount (map-get? balances { owner: tx-sender })))))
    (begin
      (asserts! (>= user-balance amount) err-insufficient-balance)
      (map-set balances { owner: tx-sender } { amount: (- user-balance amount) })
      (let ((retired-balance (default-to u0 (get amount (map-get? retired { owner: tx-sender })))))
        (map-set retired { owner: tx-sender } { amount: (+ retired-balance amount) })
      )
      ;; Reduce total supply when tokens are retired
      (var-set total-supply (- (var-get total-supply) amount))
      (ok true)
    )
  )
)

;; Read-only functions
(define-read-only (get-balance (user principal))
  (ok (default-to u0 (get amount (map-get? balances { owner: user }))))
)

(define-read-only (get-retired (user principal))
  (ok (default-to u0 (get amount (map-get? retired { owner: user }))))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-decimals)
  (ok decimals)
)

(define-read-only (get-admin)
  (ok (var-get admin))
)