;; Digital Asset Registry & Authentication Protocol
;; Decentralized content management system with cryptographic verification
;; 
;; Comprehensive blockchain-based platform for digital asset registration and management
;; Implements sophisticated authorization mechanisms with multi-tiered access controls
;; Provides immutable record-keeping for digital content with advanced metadata handling
;; Features robust validation frameworks and comprehensive error management systems

;; ===== System-wide configuration constants and administrative parameters =====

;; Primary administrative authority for the digital asset registry
(define-constant registry-administrator-principal tx-sender)

;; ===== Comprehensive error code definitions for system-wide exception handling =====

;; Asset-related error codes with detailed classification
(define-constant asset-not-found-exception (err u401))
(define-constant duplicate-asset-registration-exception (err u402))
(define-constant metadata-validation-failure-exception (err u403))
(define-constant asset-size-constraint-violation-exception (err u404))
(define-constant access-denied-exception (err u405))
(define-constant ownership-verification-failed-exception (err u406))
(define-constant administrative-privileges-required-exception (err u400))
(define-constant content-visibility-restricted-exception (err u407))
(define-constant category-validation-error-exception (err u408))

;; ===== Global state management variables =====

;; Sequential identifier tracking for digital asset registration
(define-data-var digital-asset-registry-counter uint u0)

;; ===== Core data structure definitions =====

;; Primary digital asset storage repository with comprehensive metadata schema
(define-map digital-asset-registry-storage
  { asset-identifier-key: uint }
  {
    asset-display-name: (string-ascii 64),
    asset-owner-principal: principal,
    asset-file-size-bytes: uint,
    registration-block-height: uint,
    asset-description-text: (string-ascii 128),
    asset-category-tags: (list 10 (string-ascii 32))
  }
)

;; Advanced permission management system with granular access control
(define-map access-control-permissions-registry
  { asset-identifier-key: uint, user-principal-key: principal }
  { access-permission-status: bool }
)

;; ===== Private utility functions for internal validation and processing =====

;; Individual category tag validation with comprehensive format checking
(define-private (validate-individual-category-tag (category-tag-input (string-ascii 32)))
  (and
    (> (len category-tag-input) u0)
    (< (len category-tag-input) u33)
  )
)

;; Complete category tag collection validation with integrity verification
(define-private (validate-complete-category-collection (category-tag-list (list 10 (string-ascii 32))))
  (and
    (> (len category-tag-list) u0)
    (<= (len category-tag-list) u10)
    (is-eq (len (filter validate-individual-category-tag category-tag-list)) (len category-tag-list))
  )
)

;; Asset existence verification within the digital registry
(define-private (check-asset-exists-in-registry (asset-identifier-key uint))
  (is-some (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key }))
)

;; File size extraction utility for registered digital assets
(define-private (get-asset-file-size-data (asset-identifier-key uint))
  (default-to u0
    (get asset-file-size-bytes
      (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
    )
  )
)

;; Comprehensive ownership verification mechanism with principal matching
(define-private (verify-asset-ownership-status (asset-identifier-key uint) (user-principal-to-check principal))
  (match (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
    asset-data-record (is-eq (get asset-owner-principal asset-data-record) user-principal-to-check)
    false
  )
)

;; ===== Primary public interface functions for external interaction =====

;; Comprehensive digital asset registration with extensive validation protocols
(define-public (register-new-digital-asset
  (asset-display-name (string-ascii 64))
  (asset-file-size-bytes uint)
  (asset-description-text (string-ascii 128))
  (asset-category-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (new-asset-identifier (+ (var-get digital-asset-registry-counter) u1))
    )
    ;; Comprehensive input parameter validation with detailed error reporting
    (asserts! (> (len asset-display-name) u0) metadata-validation-failure-exception)
    (asserts! (< (len asset-display-name) u65) metadata-validation-failure-exception)
    (asserts! (> asset-file-size-bytes u0) asset-size-constraint-violation-exception)
    (asserts! (< asset-file-size-bytes u1000000000) asset-size-constraint-violation-exception)
    (asserts! (> (len asset-description-text) u0) metadata-validation-failure-exception)
    (asserts! (< (len asset-description-text) u129) metadata-validation-failure-exception)
    (asserts! (validate-complete-category-collection asset-category-tags) category-validation-error-exception)
    
    ;; Execute secure asset registration in the digital registry storage
    (map-insert digital-asset-registry-storage
      { asset-identifier-key: new-asset-identifier }
      {
        asset-display-name: asset-display-name,
        asset-owner-principal: tx-sender,
        asset-file-size-bytes: asset-file-size-bytes,
        registration-block-height: block-height,
        asset-description-text: asset-description-text,
        asset-category-tags: asset-category-tags
      }
    )
    
    ;; Initialize default access permissions for the asset creator
    (map-insert access-control-permissions-registry
      { asset-identifier-key: new-asset-identifier, user-principal-key: tx-sender }
      { access-permission-status: true }
    )
    
    ;; Update the global asset registry counter for sequential tracking
    (var-set digital-asset-registry-counter new-asset-identifier)
    (ok new-asset-identifier)
  )
)

;; Advanced asset modification functionality with comprehensive validation framework
(define-public (update-existing-digital-asset
  (asset-identifier-key uint)
  (new-asset-display-name (string-ascii 64))
  (new-asset-file-size-bytes uint)
  (new-asset-description-text (string-ascii 128))
  (new-asset-category-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (current-asset-data (unwrap! (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
        asset-not-found-exception))
    )
    ;; Extensive authorization verification and parameter validation
    (asserts! (check-asset-exists-in-registry asset-identifier-key) asset-not-found-exception)
    (asserts! (is-eq (get asset-owner-principal current-asset-data) tx-sender) ownership-verification-failed-exception)
    (asserts! (> (len new-asset-display-name) u0) metadata-validation-failure-exception)
    (asserts! (< (len new-asset-display-name) u65) metadata-validation-failure-exception)
    (asserts! (> new-asset-file-size-bytes u0) asset-size-constraint-violation-exception)
    (asserts! (< new-asset-file-size-bytes u1000000000) asset-size-constraint-violation-exception)
    (asserts! (> (len new-asset-description-text) u0) metadata-validation-failure-exception)
    (asserts! (< (len new-asset-description-text) u129) metadata-validation-failure-exception)
    (asserts! (validate-complete-category-collection new-asset-category-tags) category-validation-error-exception)
    
    ;; Execute comprehensive asset data update with merged information
    (map-set digital-asset-registry-storage
      { asset-identifier-key: asset-identifier-key }
      (merge current-asset-data {
        asset-display-name: new-asset-display-name,
        asset-file-size-bytes: new-asset-file-size-bytes,
        asset-description-text: new-asset-description-text,
        asset-category-tags: new-asset-category-tags
      })
    )
    (ok true)
  )
)

;; Secure asset ownership transfer protocol with validation safeguards
(define-public (transfer-asset-ownership (asset-identifier-key uint) (new-owner-principal principal))
  (let
    (
      (existing-asset-record (unwrap! (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
        asset-not-found-exception))
    )
    ;; Rigorous ownership verification before executing transfer
    (asserts! (check-asset-exists-in-registry asset-identifier-key) asset-not-found-exception)
    (asserts! (is-eq (get asset-owner-principal existing-asset-record) tx-sender) ownership-verification-failed-exception)
    
    ;; Execute secure ownership transfer with updated principal information
    (map-set digital-asset-registry-storage
      { asset-identifier-key: asset-identifier-key }
      (merge existing-asset-record { asset-owner-principal: new-owner-principal })
    )
    (ok true)
  )
)

;; Permanent asset deletion from registry with comprehensive security validation
(define-public (remove-digital-asset-permanently (asset-identifier-key uint))
  (let
    (
      (asset-to-delete (unwrap! (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
        asset-not-found-exception))
    )
    ;; Strict ownership verification before permanent deletion
    (asserts! (check-asset-exists-in-registry asset-identifier-key) asset-not-found-exception)
    (asserts! (is-eq (get asset-owner-principal asset-to-delete) tx-sender) ownership-verification-failed-exception)
    
    ;; Execute irreversible asset removal from the digital registry
    (map-delete digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
    (ok true)
  )
)

    
  
;; ===== Read-only information retrieval functions for external queries =====

;; Comprehensive asset information retrieval with access control enforcement
(define-read-only (get-digital-asset-information (asset-identifier-key uint))
  (let
    (
      (asset-data-record (unwrap! (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
        asset-not-found-exception))
      (user-access-permission (default-to false
        (get access-permission-status
          (map-get? access-control-permissions-registry { asset-identifier-key: asset-identifier-key, user-principal-key: tx-sender })
        )
      ))
    )
    ;; Verify asset existence and access permissions before data retrieval
    (asserts! (check-asset-exists-in-registry asset-identifier-key) asset-not-found-exception)
    (asserts! (or user-access-permission (is-eq (get asset-owner-principal asset-data-record) tx-sender)) content-visibility-restricted-exception)
    
    ;; Return comprehensive asset information structure
    (ok {
      asset-display-name: (get asset-display-name asset-data-record),
      asset-owner-principal: (get asset-owner-principal asset-data-record),
      asset-file-size-bytes: (get asset-file-size-bytes asset-data-record),
      registration-block-height: (get registration-block-height asset-data-record),
      asset-description-text: (get asset-description-text asset-data-record),
      asset-category-tags: (get asset-category-tags asset-data-record)
    })
  )
)

;; Registry statistics and administrative information retrieval
(define-read-only (get-registry-system-statistics)
  (ok {
    total-assets-registered: (var-get digital-asset-registry-counter),
    registry-admin-principal: registry-administrator-principal
  })
)

;; Asset ownership verification utility for external queries
(define-read-only (get-asset-owner-information (asset-identifier-key uint))
  (match (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
    asset-record (ok (get asset-owner-principal asset-record))
    asset-not-found-exception
  )
)

;; Comprehensive access permission status verification with detailed reporting
(define-read-only (check-user-access-status (asset-identifier-key uint) (user-principal-to-check principal))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry-storage { asset-identifier-key: asset-identifier-key })
        asset-not-found-exception))
      (explicit-access-permission (default-to false
        (get access-permission-status
          (map-get? access-control-permissions-registry { asset-identifier-key: asset-identifier-key, user-principal-key: user-principal-to-check })
        )
      ))
    )
    ;; Return comprehensive access status information
    (ok {
      has-explicit-access-permission: explicit-access-permission,
      is-asset-owner: (is-eq (get asset-owner-principal asset-record) user-principal-to-check),
      can-access-asset-data: (or explicit-access-permission (is-eq (get asset-owner-principal asset-record) user-principal-to-check))
    })
  )
)

;; ===== Additional Features Extension =====
;; These functions can be added to the existing contract without modifying the original code

;; Additional error codes for new functionality
(define-constant invalid-access-grant-exception (err u409))
(define-constant permission-already-exists-exception (err u410))



;; Helper function for storage calculation
(define-private (get-asset-file-size-by-owner (asset-id uint))
  (match (map-get? digital-asset-registry-storage { asset-identifier-key: asset-id })
    asset-data (if (is-eq (get asset-owner-principal asset-data) tx-sender)
                  (get asset-file-size-bytes asset-data)
                  u0)
    u0
  )
)

;; Check if an asset exists (simple existence check)
(define-read-only (asset-exists (asset-identifier-key uint))
  (ok (check-asset-exists-in-registry asset-identifier-key))
)