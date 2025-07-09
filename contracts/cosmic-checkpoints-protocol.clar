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
