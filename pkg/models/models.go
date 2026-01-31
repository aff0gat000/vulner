package models

import "time"

// Severity levels for findings
type Severity string

const (
	SeverityCritical Severity = "CRITICAL"
	SeverityHigh     Severity = "HIGH"
	SeverityMedium   Severity = "MEDIUM"
	SeverityLow      Severity = "LOW"
	SeverityInfo     Severity = "INFO"
)

// SeverityRank returns a numeric rank for sorting (lower = more severe).
func SeverityRank(s Severity) int {
	switch s {
	case SeverityCritical:
		return 0
	case SeverityHigh:
		return 1
	case SeverityMedium:
		return 2
	case SeverityLow:
		return 3
	case SeverityInfo:
		return 4
	default:
		return 5
	}
}

// FindingType categorizes findings.
type FindingType string

const (
	FindingPackageVuln  FindingType = "PACKAGE_VULN"
	FindingCISBenchmark FindingType = "CIS_BENCHMARK"
	FindingContainer    FindingType = "CONTAINER"
)

// Package represents an installed OS package.
type Package struct {
	Name    string `json:"name"`
	Version string `json:"version"`
	Arch    string `json:"arch,omitempty"`
	Source  string `json:"source,omitempty"` // e.g. "dpkg", "rpm", "apk"
}

// Finding represents a single vulnerability or misconfiguration.
type Finding struct {
	ID          string          `json:"id"`
	Type        FindingType     `json:"type"`
	Severity    Severity        `json:"severity"`
	Title       string          `json:"title"`
	Description string          `json:"description"`
	Package     *Package        `json:"package,omitempty"`
	CVEs        []string        `json:"cves,omitempty"`
	FixedIn     string          `json:"fixed_in,omitempty"`
	References  []string        `json:"references,omitempty"`
	Remediation RemediationStep `json:"remediation"`
}

// RemediationStep describes how to fix a finding.
type RemediationStep struct {
	Summary  string `json:"summary"`
	Command  string `json:"command,omitempty"`
	Details  string `json:"details,omitempty"`
	Priority int    `json:"priority"` // lower = fix first
}

// OSInfo holds detected OS information.
type OSInfo struct {
	ID         string `json:"id"`          // e.g. "ubuntu", "debian", "alpine"
	VersionID  string `json:"version_id"`  // e.g. "22.04"
	Name       string `json:"name"`        // e.g. "Ubuntu 22.04.3 LTS"
	PrettyName string `json:"pretty_name"`
}

// ScanTarget describes what is being scanned.
type ScanTarget struct {
	Type       string `json:"type"` // "os" or "container"
	Image      string `json:"image,omitempty"`
	Dockerfile string `json:"dockerfile,omitempty"`
	RootFS     string `json:"rootfs,omitempty"` // filesystem root (/ or extracted container)
}

// ScanResult is the full output of a scan.
type ScanResult struct {
	Target    ScanTarget        `json:"target"`
	OS        OSInfo            `json:"os"`
	Findings  []Finding         `json:"findings"`
	Summary   ScanSummary       `json:"summary"`
	Timestamp time.Time         `json:"timestamp"`
	Packages  []Package         `json:"packages,omitempty"`
	Metadata  map[string]string `json:"metadata,omitempty"`
}

// ScanSummary provides counts per severity.
type ScanSummary struct {
	Total    int            `json:"total"`
	BySeverity map[Severity]int `json:"by_severity"`
	ByType     map[FindingType]int `json:"by_type"`
}

// ComputeSummary fills in the summary from findings.
func (r *ScanResult) ComputeSummary() {
	r.Summary = ScanSummary{
		Total:      len(r.Findings),
		BySeverity: make(map[Severity]int),
		ByType:     make(map[FindingType]int),
	}
	for _, f := range r.Findings {
		r.Summary.BySeverity[f.Severity]++
		r.Summary.ByType[f.Type]++
	}
}

// CISCheck represents a declarative CIS benchmark check loaded from YAML.
type CISCheck struct {
	ID          string   `yaml:"id" json:"id"`
	Title       string   `yaml:"title" json:"title"`
	Description string   `yaml:"description" json:"description"`
	Command     string   `yaml:"command" json:"command"`
	Expected    string   `yaml:"expected" json:"expected"`
	Operator    string   `yaml:"operator" json:"operator"` // "equals", "contains", "not_contains", "regex"
	Severity    Severity `yaml:"severity" json:"severity"`
	Remediation string   `yaml:"remediation" json:"remediation"`
	RemCommand  string   `yaml:"rem_command" json:"rem_command"`
}

// ContainerCheck represents a container best-practice check from YAML.
type ContainerCheck struct {
	ID          string   `yaml:"id" json:"id"`
	Title       string   `yaml:"title" json:"title"`
	Description string   `yaml:"description" json:"description"`
	CheckType   string   `yaml:"check_type" json:"check_type"` // "dockerfile", "image"
	Pattern     string   `yaml:"pattern" json:"pattern"`
	Operator    string   `yaml:"operator" json:"operator"` // "not_found", "found"
	Severity    Severity `yaml:"severity" json:"severity"`
	Remediation string   `yaml:"remediation" json:"remediation"`
}
