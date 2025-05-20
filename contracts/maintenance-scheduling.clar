;; maintenance-scheduling.clar
;; This contract coordinates building upkeep

(define-data-var admin principal tx-sender)

;; Map to store maintenance tasks
(define-map maintenance-tasks
  { task-id: (string-ascii 36) }
  {
    building-id: (string-ascii 36),
    description: (string-ascii 100),
    scheduled-date: uint,
    completed: bool,
    assigned-to: principal
  }
)

;; Map to track building maintenance history
(define-map building-maintenance-count
  { building-id: (string-ascii 36) }
  {
    pending-tasks: uint,
    completed-tasks: uint
  }
)

;; Public function to create a maintenance task
(define-public (create-maintenance-task
                (task-id (string-ascii 36))
                (building-id (string-ascii 36))
                (description (string-ascii 100))
                (scheduled-date uint)
                (assigned-to principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    ;; Insert the task
    (map-insert maintenance-tasks
      { task-id: task-id }
      {
        building-id: building-id,
        description: description,
        scheduled-date: scheduled-date,
        completed: false,
        assigned-to: assigned-to
      }
    )

    ;; Update the building maintenance count
    (match (map-get? building-maintenance-count { building-id: building-id })
      count-data (map-set building-maintenance-count
                  { building-id: building-id }
                  {
                    pending-tasks: (+ (get pending-tasks count-data) u1),
                    completed-tasks: (get completed-tasks count-data)
                  })
      (map-insert building-maintenance-count
        { building-id: building-id }
        { pending-tasks: u1, completed-tasks: u0 }
      )
    )

    (ok true)
  )
)

;; Public function to mark a task as completed
(define-public (complete-maintenance-task (task-id (string-ascii 36)))
  (begin
    (match (map-get? maintenance-tasks { task-id: task-id })
      task (begin
        (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get assigned-to task))) (err u3))
        (asserts! (not (get completed task)) (err u5))

        ;; Update the task
        (map-set maintenance-tasks
          { task-id: task-id }
          (merge task { completed: true })
        )

        ;; Update the building maintenance count
        (match (map-get? building-maintenance-count { building-id: (get building-id task) })
          count-data (ok (map-set building-maintenance-count
                      { building-id: (get building-id task) }
                      {
                        pending-tasks: (- (get pending-tasks count-data) u1),
                        completed-tasks: (+ (get completed-tasks count-data) u1)
                      }))
          (err u2)
        )
      )
      (err u2)
    )
  )
)

;; Read-only function to get task details
(define-read-only (get-task-details (task-id (string-ascii 36)))
  (map-get? maintenance-tasks { task-id: task-id })
)

;; Read-only function to get building maintenance stats
(define-read-only (get-building-maintenance-stats (building-id (string-ascii 36)))
  (map-get? building-maintenance-count { building-id: building-id })
)
