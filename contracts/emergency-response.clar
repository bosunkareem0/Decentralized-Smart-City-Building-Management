;; emergency-response.clar
;; This contract manages crisis protocols

(define-data-var admin principal tx-sender)

;; Map to store emergency protocols
(define-map emergency-protocols
  { protocol-id: (string-ascii 36) }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    severity-level: uint
  }
)

;; Map to store building emergency status
(define-map building-emergency-status
  { building-id: (string-ascii 36) }
  {
    active-emergency: bool,
    protocol-id: (string-ascii 36),
    activated-at: uint,
    activated-by: principal
  }
)

;; Public function to register an emergency protocol
(define-public (register-protocol
                (protocol-id (string-ascii 36))
                (name (string-ascii 50))
                (description (string-ascii 200))
                (severity-level uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (map-insert emergency-protocols
      { protocol-id: protocol-id }
      {
        name: name,
        description: description,
        severity-level: severity-level
      }
    ))
  )
)

;; Public function to activate emergency protocol for a building
(define-public (activate-emergency
                (building-id (string-ascii 36))
                (protocol-id (string-ascii 36)))
  (begin
    ;; Check if protocol exists
    (asserts! (is-some (map-get? emergency-protocols { protocol-id: protocol-id })) (err u2))

    ;; Activate emergency for building
    (ok (map-set building-emergency-status
        { building-id: building-id }
        {
          active-emergency: true,
          protocol-id: protocol-id,
          activated-at: block-height,
          activated-by: tx-sender
        }
      ))
  )
)

;; Public function to deactivate emergency for a building
(define-public (deactivate-emergency (building-id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (match (map-get? building-emergency-status { building-id: building-id })
      status (begin
        (asserts! (get active-emergency status) (err u6))
        (ok (map-set building-emergency-status
            { building-id: building-id }
            (merge status { active-emergency: false })
          ))
      )
      (err u2)
    )
  )
)

;; Read-only function to get protocol details
(define-read-only (get-protocol-details (protocol-id (string-ascii 36)))
  (map-get? emergency-protocols { protocol-id: protocol-id })
)

;; Read-only function to get building emergency status
(define-read-only (get-building-emergency-status (building-id (string-ascii 36)))
  (map-get? building-emergency-status { building-id: building-id })
)

;; Read-only function to check if building has active emergency
(define-read-only (has-active-emergency (building-id (string-ascii 36)))
  (match (map-get? building-emergency-status { building-id: building-id })
    status (get active-emergency status)
    false
  )
)
