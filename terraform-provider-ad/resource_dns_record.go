package ad

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func resourceDNSRecord() *schema.Resource {
	return &schema.Resource{
		Create: resourceDNSRecordCreate,
		Read:   resourceDNSRecordRead,
		Update: resourceDNSRecordUpdate,
		Delete: resourceDNSRecordDelete,
		Schema: map[string]*schema.Schema{
			"zone": {
				Type:     schema.TypeString,
				Required: true,
			},
			"name": {
				Type:     schema.TypeString,
				Required: true,
			},
			"record_type": {
				Type:     schema.TypeString,
				Required: true,
			},
			"value": {
				Type:     schema.TypeString,
				Required: true,
			},
			"ttl": {
				Type:     schema.TypeInt,
				Required: true,
			},
		},
	}
}

func resourceDNSRecordCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	zone := d.Get("zone").(string)
	name := d.Get("name").(string)
	recordType := d.Get("record_type").(string)
	value := d.Get("value").(string)
	ttl := d.Get("ttl").(int)

	resp, err := client.CreateDNSRecord(zone, name, recordType, value, ttl)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusCreated {
		return fmt.Errorf("failed to create DNS record, status: %s", resp.Status)
	}

	body, _ := ioutil.ReadAll(resp.Body)
	d.SetId(string(body))
	return resourceDNSRecordRead(d, m)
}

func resourceDNSRecordRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	zone := d.Get("zone").(string)
	name := d.Get("name").(string)

	resp, err := client.GetDNSRecord(zone, name)
	if err != nil {
		return err
	}
	if resp.StatusCode == http.StatusNotFound {
		d.SetId("")
		return nil
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to read DNS record, status: %s", resp.Status)
	}

	var record map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&record); err != nil {
		return fmt.Errorf("failed to decode DNS record response: %v", err)
	}

	d.Set("record_type", record["record_type"])
	d.Set("value", record["value"])
	d.Set("ttl", record["ttl"])

	return nil
}

func resourceDNSRecordUpdate(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	zone := d.Get("zone").(string)
	name := d.Get("name").(string)
	recordType := d.Get("record_type").(string)
	value := d.Get("value").(string)
	ttl := d.Get("ttl").(int)

	resp, err := client.UpdateDNSRecord(zone, name, recordType, value, ttl)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to update DNS record, status: %s", resp.Status)
	}

	return resourceDNSRecordRead(d, m)
}

func resourceDNSRecordDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	zone := d.Get("zone").(string)
	name := d.Get("name").(string)

	resp, err := client.DeleteDNSRecord(zone, name)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("failed to delete DNS record, status: %s", resp.Status)
	}

	d.SetId("")
	return nil
}
