;; building-verification.clar
;; This contract validates urban structures

(define-data-var admin principal tx-sender)

;; Map to store verified buildings
(define-map verified-buildings
  { building-id: (string-ascii 36) }
  {
    owner: principal,
    status: (string-ascii 20),
    verification-date: uint,
    location: (string-ascii 100)
  }
)

;; Public function to register a new building
(define-public (register-building
                (building-id (string-ascii 36))
                (location (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (map-insert verified-buildings
      { building-id: building-id }
      {
        owner: tx-sender,
        status: "pending",
        verification-date: block-height,
        location: location
      }
    ))
  )
)

;; Public function to verify a building
(define-public (verify-building
                (building-id (string-ascii 36))
                (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (match (map-get? verified-buildings { building-id: building-id })
      building (ok (map-set verified-buildings
                  { building-id: building-id }
                  (merge building {
                    status: new-status,
                    verification-date: block-height
                  })
                ))
      (err u2)
    )
  )
)

;; Read-only function to get building details
(define-read-only (get-building-details (building-id (string-ascii 36)))
  (map-get? verified-buildings { building-id: building-id })
)

;; Function to transfer building ownership
(define-public (transfer-building-ownership
                (building-id (string-ascii 36))
                (new-owner principal))
  (begin
    (match (map-get? verified-buildings { building-id: building-id })
      building (begin
        (asserts! (is-eq tx-sender (get owner building)) (err u3))
        (ok (map-set verified-buildings
            { building-id: building-id }
            (merge building { owner: new-owner })
          ))
      )
      (err u2)
    )
  )
)

;; Function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (var-set admin new-admin))
  )
)
