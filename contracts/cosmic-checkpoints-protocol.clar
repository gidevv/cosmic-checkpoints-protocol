;; CosmicCheckpoints Protocol
;; A Milestone tracking system with secure entity-based data association

;; Links participant principals to their milestone configurations
(define-map milestone-registry
    principal
    {
        description: (string-ascii 100),
        status: bool
    }
)

;; System response constants for operational status reporting
(define-constant MILESTONE-DUPLICATE-ENTRY (err u409))
(define-constant MILESTONE-INVALID-PAYLOAD (err u400))
(define-constant MILESTONE-NOT-FOUND (err u404))

;; Temporal scheduling repository for milestone deadlines
;; Manages target completion blocks and notification tracking
(define-map schedule-tracking
    principal
    {
        deadline-block: uint,
        notification-sent: bool
    }
)

;; Priority classification storage for milestone hierarchies
;; Supports multi-level priority assignment system
(define-map priority-levels
    principal
    {
        priority-rank: uint
    }
)

;; Administrative function to create new milestone entry
(define-public (create-milestone-entry 
    (description (string-ascii 100)))
    (let
        (
            (participant tx-sender)
            (current-record (map-get? milestone-registry participant))
        )
        (if (is-none current-record)
            (begin
                (if (is-eq description "")
                    (err MILESTONE-INVALID-PAYLOAD)
                    (begin
                        (map-set milestone-registry participant
                            {
                                description: description,
                                status: false
                            }
                        )
                        (ok "Milestone entry creation successful.")
                    )
                )
            )
            (err MILESTONE-DUPLICATE-ENTRY)
        )
    )
)

;; Administrative function to modify milestone record attributes
(define-public (modify-milestone-record
    (description (string-ascii 100))
    (status bool))
    (let
        (
            (participant tx-sender)
            (current-record (map-get? milestone-registry participant))
        )
        (if (is-some current-record)
            (begin
                (if (is-eq description "")
                    (err MILESTONE-INVALID-PAYLOAD)
                    (begin
                        (if (or (is-eq status true) (is-eq status false))
                            (begin
                                (map-set milestone-registry participant
                                    {
                                        description: description,
                                        status: status
                                    }
                                )
                                (ok "Milestone record modification successful.")
                            )
                            (err MILESTONE-INVALID-PAYLOAD)
                        )
                    )
                )
            )
            (err MILESTONE-NOT-FOUND)
        )
    )
)

;; Administrative function to remove milestone from registry
(define-public (remove-milestone-entry)
    (let
        (
            (participant tx-sender)
            (current-record (map-get? milestone-registry participant))
        )
        (if (is-some current-record)
            (begin
                (map-delete milestone-registry participant)
                (ok "Milestone entry removal successful.")
            )
            (err MILESTONE-NOT-FOUND)
        )
    )
)

;; Configuration function to set milestone completion deadline
(define-public (configure-milestone-deadline (block-offset uint))
    (let
        (
            (participant tx-sender)
            (current-record (map-get? milestone-registry participant))
            (target-deadline (+ block-height block-offset))
        )
        (if (is-some current-record)
            (if (> block-offset u0)
                (begin
                    (map-set schedule-tracking participant
                        {
                            deadline-block: target-deadline,
                            notification-sent: false
                        }
                    )
                    (ok "Milestone deadline configuration successful.")
                )
                (err MILESTONE-INVALID-PAYLOAD)
            )
            (err MILESTONE-NOT-FOUND)
        )
    )
)

;; Configuration function to establish milestone priority classification
(define-public (establish-priority-classification (priority-rank uint))
    (let
        (
            (participant tx-sender)
            (current-record (map-get? milestone-registry participant))
        )
        (if (is-some current-record)
            (if (and (>= priority-rank u1) (<= priority-rank u3))
                (begin
                    (map-set priority-levels participant
                        {
                            priority-rank: priority-rank
                        }
                    )
                    (ok "Priority classification establishment successful.")
                )
                (err MILESTONE-INVALID-PAYLOAD)
            )
            (err MILESTONE-NOT-FOUND)
        )
    )
)

;; Query function to authenticate milestone existence and extract metadata
(define-public (authenticate-milestone-existence)
    (let
        (
            (participant tx-sender)
            (current-record (map-get? milestone-registry participant))
        )
        (if (is-some current-record)
            (let
                (
                    (record-data (unwrap! current-record MILESTONE-NOT-FOUND))
                    (milestone-description (get description record-data))
                    (milestone-status (get status record-data))
                )
                (ok {
                    exists: true,
                    description-length: (len milestone-description),
                    is-completed: milestone-status
                })
            )
            (ok {
                exists: false,
                description-length: u0,
                is-completed: false
            })
        )
    )
)

;; Transfer function enabling milestone assignment to designated participants
(define-public (transfer-milestone-assignment
    (destination-participant principal)
    (description (string-ascii 100)))
    (let
        (
            (existing-record (map-get? milestone-registry destination-participant))
        )
        (if (is-none existing-record)
            (begin
                (if (is-eq description "")
                    (err MILESTONE-INVALID-PAYLOAD)
                    (begin
                        (map-set milestone-registry destination-participant
                            {
                                description: description,
                                status: false
                            }
                        )
                        (ok "Milestone assignment transfer successful.")
                    )
                )
            )
            (err MILESTONE-DUPLICATE-ENTRY)
        )
    )
)

