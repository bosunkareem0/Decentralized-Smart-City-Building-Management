;; occupancy-tracking.clar
;; This contract monitors space utilization

(define-data-var admin principal tx-sender)

;; Map to store building occupancy data
(define-map building-occupancy
  { building-id: (string-ascii 36) }
  {
    current-occupancy: uint,
    max-capacity: uint,
    last-updated: uint
  }
)

;; Public function to register a building for occupancy tracking
(define-public (register-building-occupancy
                (building-id (string-ascii 36))
                (max-capacity uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (map-insert building-occupancy
      { building-id: building-id }
      {
        current-occupancy: u0,
        max-capacity: max-capacity,
        last-updated: block-height
      }
    ))
  )
)

;; Public function to update occupancy
(define-public (update-occupancy
                (building-id (string-ascii 36))
                (new-occupancy uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (match (map-get? building-occupancy { building-id: building-id })
      occupancy-data (begin
        (asserts! (<= new-occupancy (get max-capacity occupancy-data)) (err u4))
        (ok (map-set building-occupancy
            { building-id: building-id }
            (merge occupancy-data {
              current-occupancy: new-occupancy,
              last-updated: block-height
            })
          ))
      )
      (err u2)
    )
  )
)

;; Read-only function to get occupancy details
(define-read-only (get-occupancy-details (building-id (string-ascii 36)))
  (map-get? building-occupancy { building-id: building-id })
)

;; Read-only function to check if building is at capacity
(define-read-only (is-at-capacity (building-id (string-ascii 36)))
  (match (map-get? building-occupancy { building-id: building-id })
    occupancy-data (is-eq (get current-occupancy occupancy-data) (get max-capacity occupancy-data))
    false
  )
)

;; Function to update max capacity
(define-public (update-max-capacity
                (building-id (string-ascii 36))
                (new-max-capacity uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (match (map-get? building-occupancy { building-id: building-id })
      occupancy-data (ok (map-set building-occupancy
          { building-id: building-id }
          (merge occupancy-data { max-capacity: new-max-capacity })
        ))
      (err u2)
    )
  )
)
