package ad

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
)

// Client is used to interact with the AD Management API.
type Client struct {
	BaseURL string
}

// NewClient creates a new instance of Client with the provided base URL.
func NewClient(baseURL string) *Client {
	return &Client{
		BaseURL: baseURL,
	}
}

// CreateDNSRecord sends a request to create a DNS record.
func (c *Client) CreateDNSRecord(zone, name, recordType, value string, ttl int) (*http.Response, error) {
	record := map[string]interface{}{
		"zone":        zone,
		"name":        name,
		"record_type": recordType,
		"value":       value,
		"ttl":         ttl,
	}
	body, _ := json.Marshal(record)

	resp, err := http.Post(fmt.Sprintf("%s/dns-records", c.BaseURL), "application/json", bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// GetDNSRecord retrieves a DNS record by zone and name.
func (c *Client) GetDNSRecord(zone, name string) (*http.Response, error) {
	resp, err := http.Get(fmt.Sprintf("%s/dns-records/%s/%s", c.BaseURL, zone, name))
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// UpdateDNSRecord sends a request to update an existing DNS record.
func (c *Client) UpdateDNSRecord(zone, name, recordType, value string, ttl int) (*http.Response, error) {
	record := map[string]interface{}{
		"record_type": recordType,
		"value":       value,
		"ttl":         ttl,
	}
	body, _ := json.Marshal(record)

	req, err := http.NewRequest(http.MethodPut, fmt.Sprintf("%s/dns-records/%s/%s", c.BaseURL, zone, name), bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// DeleteDNSRecord sends a request to delete a DNS record.
func (c *Client) DeleteDNSRecord(zone, name string) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodDelete, fmt.Sprintf("%s/dns-records/%s/%s", c.BaseURL, zone, name), nil)
	if err != nil {
		return nil, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// CreateCertificate sends a request to create a certificate.
func (c *Client) CreateCertificate(templateName, subjectName string) (*http.Response, error) {
	certificate := map[string]string{
		"template_name": templateName,
		"subject_name":  subjectName,
	}
	body, _ := json.Marshal(certificate)

	resp, err := http.Post(fmt.Sprintf("%s/certificates", c.BaseURL), "application/json", bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// GetCertificate retrieves a certificate by template and subject names.
func (c *Client) GetCertificate(templateName, subjectName string) (*http.Response, error) {
	resp, err := http.Get(fmt.Sprintf("%s/certificates/%s/%s", c.BaseURL, templateName, subjectName))
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// UpdateCertificate sends a request to update an existing certificate.
func (c *Client) UpdateCertificate(templateName, subjectName string) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodPut, fmt.Sprintf("%s/certificates/%s/%s", c.BaseURL, templateName, subjectName), nil)
	if err != nil {
		return nil, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// DeleteCertificate sends a request to delete a certificate.
func (c *Client) DeleteCertificate(templateName, subjectName string) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodDelete, fmt.Sprintf("%s/certificates/%s/%s", c.BaseURL, templateName, subjectName), nil)
	if err != nil {
		return nil, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	return resp, nil
}
