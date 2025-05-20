;; energy-management.clar
;; This contract optimizes resource consumption

(define-data-var admin principal tx-sender)

;; Map to store building energy data
(define-map building-energy
  { building-id: (string-ascii 36) }
  {
    current-usage: uint,
    daily-limit: uint,
    last-updated: uint,
    energy-efficient: bool
  }
)

;; Public function to register a building for energy management
(define-public (register-building-energy
                (building-id (string-ascii 36))
                (daily-limit uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (map-insert building-energy
      { building-id: building-id }
      {
        current-usage: u0,
        daily-limit: daily-limit,
        last-updated: block-height,
        energy-efficient: true
      }
    ))
  )
)

;; Public function to update energy usage
(define-public (update-energy-usage
                (building-id (string-ascii 36))
                (usage uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (match (map-get? building-energy { building-id: building-id })
      energy-data (begin
        (ok (map-set building-energy
            { building-id: building-id }
            (merge energy-data {
              current-usage: (+ (get current-usage energy-data) usage),
              last-updated: block-height,
              energy-efficient: (<= (+ (get current-usage energy-data) usage) (get daily-limit energy-data))
            })
          ))
      )
      (err u2)
    )
  )
)

;; Public function to reset daily usage
(define-public (reset-daily-usage (building-id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (match (map-get? building-energy { building-id: building-id })
      energy-data (ok (map-set building-energy
          { building-id: building-id }
          (merge energy-data {
            current-usage: u0,
            last-updated: block-height,
            energy-efficient: true
          })
        ))
      (err u2)
    )
  )
)

;; Read-only function to get energy details
(define-read-only (get-energy-details (building-id (string-ascii 36)))
  (map-get? building-energy { building-id: building-id })
)

;; Read-only function to check if building is energy efficient
(define-read-only (is-energy-efficient (building-id (string-ascii 36)))
  (match (map-get? building-energy { building-id: building-id })
    energy-data (get energy-efficient energy-data)
    false
  )
)
