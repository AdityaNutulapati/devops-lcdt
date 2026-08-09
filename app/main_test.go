package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// Test the / endpoint
func TestHelloHandler(t *testing.T) {
	// Create fake request and response
	req := httptest.NewRequest("GET", "/", nil)
	rec := httptest.NewRecorder()

	// Call the handler
	helloHandler(rec, req)

	// Check status code
	if rec.Code != 200 {
		t.Errorf("expected status 200, got %d", rec.Code)
	}

	// Check response body
	if rec.Body.String() != "Hello World" {
		t.Errorf("expected 'Hello World', got %q", rec.Body.String())
	}
}

// Test the /health endpoint
func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest("GET", "/health", nil)
	rec := httptest.NewRecorder()

	healthHandler(rec, req)

	// Check status and response
	if rec.Code != 200 {
		t.Errorf("expected status 200, got %d", rec.Code)
	}

	if rec.Body.String() != `{"status":"ok"}` {
		t.Errorf("expected ok status, got %q", rec.Body.String())
	}
}

// Test the /ready endpoint
func TestReadinessHandler(t *testing.T) {
	req := httptest.NewRequest("GET", "/ready", nil)
	rec := httptest.NewRecorder()

	readinessHandler(rec, req)

	// Check status and response
	if rec.Code != 200 {
		t.Errorf("expected status 200, got %d", rec.Code)
	}

	if rec.Body.String() != `{"status":"ready"}` {
		t.Errorf("expected ready status, got %q", rec.Body.String())
	}
}
