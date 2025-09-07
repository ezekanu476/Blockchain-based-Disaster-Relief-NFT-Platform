(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_PROJECT_ID (err u101))
(define-constant ERR_INVALID_ADDRESS (err u102))
(define-constant ERR_INVALID_DESCRIPTION (err u103))
(define-constant ERR_INVALID_MILESTONE (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_PROJECT_ALREADY_EXISTS (err u106))
(define-constant ERR_PROJECT_NOT_FOUND (err u107))
(define-constant ERR_INSUFFICIENT_FUNDS (err u108))
(define-constant ERR_MILESTONE_NOT_ACHIEVED (err u109))
(define-constant ERR_DISTRIBUTION_ALREADY_APPROVED (err u110))
(define-constant ERR_DISTRIBUTION_NOT_APPROVED (err u111))
(define-constant ERR_INVALID_VOTE (err u112))
(define-constant ERR_VOTING_PERIOD_ENDED (err u113))
(define-constant ERR_VOTING_PERIOD_ACTIVE (err u114))
(define-constant ERR_MAX_PROJECTS_EXCEEDED (err u115))
(define-constant ERR_INVALID_TIMESTAMP (err u116))
(define-constant ERR_INVALID_PERCENTAGE (err u117))
(define-constant ERR_ALLOCATION_EXCEEDED (err u118))
(define-constant ERR_INVALID_STATUS (err u119))
(define-constant ERR_LOGGING_FAILED (err u120))
(define-constant ERR_GOVERNANCE_NOT_VERIFIED (err u121))
(define-constant ERR_ESCROW_NOT_VERIFIED (err u122))
(define-constant ERR_INVALID_PROPOSAL_ID (err u123))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u124))
(define-constant ERR_PROPOSAL_ALREADY_EXECUTED (err u125))

(define-data-var admin principal tx-sender)
(define-data-var next-project-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var max-projects uint u500)
(define-data-var voting-period uint u144)
(define-data-var governance-contract principal 'SP000000000000000000002Q6VF78.governance-dao)
(define-data-var escrow-contract principal 'SP000000000000000000002Q6VF78.escrow-vault)
(define-data-var audit-logger-contract principal 'SP000000000000000000002Q6VF78.audit-logger)

;; Projects indexed by numeric id
(define-map projects
  uint
  {
    recipient: principal,
    description: (string-utf8 500),
    total-allocated: uint,
    total-released: uint,
    milestones: (list 10 { description: (string-utf8 200), achieved: bool, amount: uint }),
    status: (string-ascii 20),
    registration-timestamp: uint
  }
)

;; Index to enforce 1 project per recipient principal (optional policy)
(define-map recipient-index
  principal
  uint)

(define-map proposals
  uint
  {
    project-id: uint,
    amount: uint,
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    start-block: uint,
    end-block: uint,
    executed: bool
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  bool
)

(define-map funds-balance principal uint)

(define-read-only (get-project (project-id uint))
  (map-get? projects project-id)
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? funds-balance account)))
)

(define-read-only (get-next-project-id)
  (ok (var-get next-project-id))
)

(define-read-only (get-next-proposal-id)
  (ok (var-get next-proposal-id))
)

;; Basic placeholder; extend if you want stricter checks
(define-private (validate-principal (p principal))
  (ok true)
)

(define-private (validate-description (desc (string-utf8 500)))
  (if (and (> (len desc) u0) (<= (len desc) u500))
    (ok true)
    ERR_INVALID_DESCRIPTION)
)

(define-private (validate-amount (amt uint))
  (if (> amt u0)
    (ok true)
    ERR_INVALID_AMOUNT)
)

(define-private (validate-milestone (m { description: (string-utf8 200), achieved: bool, amount: uint }))
  (try! (validate-description (get description m)))
  (validate-amount (get amount m))
)

(define-private (validate-milestones (ms (list 10 { description: (string-utf8 200), achieved: bool, amount: uint })))
  (fold check-milestone ms (ok true))
)

(define-private (check-milestone (m { description: (string-utf8 200), achieved: bool, amount: uint }) (acc (response bool uint)))
  (match acc
    ok-value (validate-milestone m)
    err-value acc)
)

(define-private (validate-status (s (string-ascii 20)))
  (if (or (is-eq s "active") (is-eq s "completed") (is-eq s "cancelled"))
    (ok true)
    ERR_INVALID_STATUS)
)

(define-private (validate-timestamp (ts uint))
  (if (>= ts block-height)
    (ok true)
    ERR_INVALID_TIMESTAMP)
)

(define-private (is-admin (caller principal))
  (is-eq caller (var-get admin))
)

(define-private (is-governance-approved (proposal-id uint))
  (match (get-proposal proposal-id)
    p (and (> (get votes-for p) (get votes-against p)) (>= block-height (get end-block p)) (not (get executed p)))
    false)
)

;; --- admin setters ---

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (try! (validate-principal new-admin))
    (var-set admin new-admin)
    (ok true))
)

(define-public (set-max-projects (new-max uint))
  (begin
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (var-set max-projects new-max)
    (ok true))
)

(define-public (set-voting-period (new-period uint))
  (begin
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (> new-period u0) ERR_INVALID_AMOUNT)
    (var-set voting-period new-period)
    (ok true))
)

(define-public (set-governance-contract (new-gov principal))
  (begin
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (try! (validate-principal new-gov))
    (var-set governance-contract new-gov)
    (ok true))
)

(define-public (set-escrow-contract (new-escrow principal))
  (begin
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (try! (validate-principal new-escrow))
    (var-set escrow-contract new-escrow)
    (ok true))
)

(define-public (set-audit-logger-contract (new-logger principal))
  (begin
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (try! (validate-principal new-logger))
    (var-set audit-logger-contract new-logger)
    (ok true))
)

;; --- project lifecycle ---

(define-public (register-project
  (recipient principal)
  (description (string-utf8 500))
  (milestones (list 10 { description: (string-utf8 200), achieved: bool, amount: uint }))
  (status (string-ascii 20)))
  (let ((project-id (var-get next-project-id)))
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (< project-id (var-get max-projects)) ERR_MAX_PROJECTS_EXCEEDED)
    (try! (validate-principal recipient))
    (try! (validate-description description))
    (try! (validate-milestones milestones))
    (try! (validate-status status))
    ;; ensure recipient doesn't already have a project
    (asserts! (is-none (map-get? recipient-index recipient)) ERR_PROJECT_ALREADY_EXISTS)
    (map-set projects project-id
      {
        recipient: recipient,
        description: description,
        total-allocated: u0,
        total-released: u0,
        milestones: milestones,
        status: status,
        registration-timestamp: block-height
      }
    )
    (map-set recipient-index recipient project-id)
    (var-set next-project-id (+ project-id u1))
    (try! (contract-call? (var-get audit-logger-contract) log-event "project-registered" project-id tx-sender block-height))
    (ok project-id))
)

;; --- governance + distributions ---

(define-public (propose-distribution (project-id uint) (amount uint))
  (let (
        (proposal-id (var-get next-proposal-id))
        (project (unwrap! (get-project project-id) ERR_PROJECT_NOT_FOUND))
       )
    (asserts! (contract-call? (var-get governance-contract) is-eligible-voter tx-sender) ERR_NOT_AUTHORIZED)
    (try! (validate-amount amount))
    (asserts! (<= amount (as-contract (stx-get-balance tx-sender))) ERR_INSUFFICIENT_FUNDS)
    (map-set proposals proposal-id
      {
        project-id: project-id,
        amount: amount,
        proposer: tx-sender,
        votes-for: u0,
        votes-against: u0,
        start-block: block-height,
        end-block: (+ block-height (var-get voting-period)),
        executed: false
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (try! (contract-call? (var-get audit-logger-contract) log-event "distribution-proposed" proposal-id tx-sender block-height))
    (ok proposal-id))
)

(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let ((proposal (unwrap! (get-proposal proposal-id) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (contract-call? (var-get governance-contract) is-eligible-voter tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (< block-height (get end-block proposal)) ERR_VOTING_PERIOD_ENDED)
    (asserts! (is-none (get-vote proposal-id tx-sender)) ERR_INVALID_VOTE)
    (if vote
      (map-set proposals proposal-id (merge proposal {votes-for: (+ (get votes-for proposal) u1)}))
      (map-set proposals proposal-id (merge proposal {votes-against: (+ (get votes-against proposal) u1)})))
    (map-set votes {proposal-id: proposal-id, voter: tx-sender} vote)
    (try! (contract-call? (var-get audit-logger-contract) log-event "vote-cast" proposal-id tx-sender block-height))
    (ok true))
)

(define-public (execute-distribution (proposal-id uint))
  (let ((proposal (unwrap! (get-proposal proposal-id) ERR_PROPOSAL_NOT_FOUND))
        (project-id (get project-id proposal))
        (amount (get amount proposal))
        (project (unwrap! (get-project project-id) ERR_PROJECT_NOT_FOUND)))
    (asserts! (>= block-height (get end-block proposal)) ERR_VOTING_PERIOD_ACTIVE)
    (asserts! (not (get executed proposal)) ERR_PROPOSAL_ALREADY_EXECUTED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR_DISTRIBUTION_NOT_APPROVED)
    (asserts! (<= amount (as-contract (stx-get-balance tx-sender))) ERR_INSUFFICIENT_FUNDS)
    (try! (as-contract (stx-transfer? amount tx-sender (get recipient project))))
    (map-set projects project-id (merge project {total-released: (+ (get total-released project) amount)}))
    (map-set proposals proposal-id (merge proposal {executed: true}))
    (try! (contract-call? (var-get audit-logger-contract) log-event "distribution-executed" proposal-id tx-sender block-height))
    (ok true))
)

;; --- escrow ingress + internal accounting ---

(define-public (receive-funds-from-escrow (amount uint) (sender principal))
  (begin
    (asserts! (is-eq tx-sender (var-get escrow-contract)) ERR_NOT_AUTHORIZED)
    (try! (validate-amount amount))
    (try! (stx-transfer? amount sender (as-contract tx-sender)))
    (map-set funds-balance
             (as-contract tx-sender)
             (+ (default-to u0 (map-get? funds-balance (as-contract tx-sender))) amount))
    (try! (contract-call? (var-get audit-logger-contract) log-event "funds-received" amount sender block-height))
    (ok true))
)

(define-public (update-milestone (project-id uint) (milestone-index uint) (achieved bool))
  (let ((project (unwrap! (get-project project-id) ERR_PROJECT_NOT_FOUND))
        (milestones (get milestones project)))
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (< milestone-index (len milestones)) ERR_INVALID_MILESTONE)
    (let ((updated-milestone (merge (element-at milestones milestone-index) {achieved: achieved})))
      (map-set projects project-id (merge project {milestones: (replace-at milestones milestone-index updated-milestone)})))
    (try! (contract-call? (var-get audit-logger-contract) log-event "milestone-updated" project-id tx-sender block-height))
    (ok true))
)

(define-public (allocate-funds (project-id uint) (amount uint))
  (let ((project (unwrap! (get-project project-id) ERR_PROJECT_NOT_FOUND)))
    (asserts! (is-admin tx-sender) ERR_NOT_AUTHORIZED)
    (try! (validate-amount amount))
    (asserts! (<= amount (default-to u0 (map-get? funds-balance (as-contract tx-sender)))) ERR_INSUFFICIENT_FUNDS)
    (map-set projects project-id (merge project {total-allocated: (+ (get total-allocated project) amount)}))
    (map-set funds-balance (as-contract tx-sender) (- (default-to u0 (map-get? funds-balance (as-contract tx-sender))) amount))
    (try! (contract-call? (var-get audit-logger-contract) log-event "funds-allocated" amount tx-sender block-height))
    (ok true))
)

(define-public (release-funds-for-milestone (project-id uint) (milestone-index uint))
  (let ((project (unwrap! (get-project project-id) ERR_PROJECT_NOT_FOUND))
        (milestones (get milestones project))
        (milestone (element-at milestones milestone-index)))
    (asserts! (get achieved milestone) ERR_MILESTONE_NOT_ACHIEVED)
    (let ((amount (get amount milestone)))
      (asserts! (<= amount (get total-allocated project)) ERR_ALLOCATION_EXCEEDED)
      (try! (as-contract (stx-transfer? amount tx-sender (get recipient project))))
      (map-set projects project-id (merge project {
        total-released: (+ (get total-released project) amount),
        total-allocated: (- (get total-allocated project) amount)
      }))
      (try! (contract-call? (var-get audit-logger-contract) log-event "milestone-released" project-id tx-sender block-height))
      (ok amount)))
)
