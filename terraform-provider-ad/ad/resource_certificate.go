package ad

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func resourceCertificate() *schema.Resource {
	return &schema.Resource{
		Create: resourceCertificateCreate,
		Read:   resourceCertificateRead,
		Update: resourceCertificateUpdate,
		Delete: resourceCertificateDelete,
		Schema: map[string]*schema.Schema{
			"template_name": {
				Type:     schema.TypeString,
				Required: true,
			},
			"subject_name": {
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

func resourceCertificateCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	templateName := d.Get("template_name").(string)
	subjectName := d.Get("subject_name").(string)

	resp, err := client.CreateCertificate(templateName, subjectName)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusCreated {
		return fmt.Errorf("failed to create certificate, status: %s", resp.Status)
	}

	body, _ := ioutil.ReadAll(resp.Body)
	d.SetId(string(body)) // Adjust this based on your API's response format
	return resourceCertificateRead(d, m)
}

func resourceCertificateRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	templateName := d.Get("template_name").(string)
	subjectName := d.Get("subject_name").(string)

	resp, err := client.GetCertificate(templateName, subjectName)
	if err != nil {
		return err
	}
	if resp.StatusCode == http.StatusNotFound {
		d.SetId("")
		return nil
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to read certificate, status: %s", resp.Status)
	}

	var cert map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&cert); err != nil {
		return fmt.Errorf("failed to decode certificate response: %v", err)
	}

	d.Set("template_name", cert["template_name"])
	d.Set("subject_name", cert["subject_name"])

	return nil
}

func resourceCertificateUpdate(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	templateName := d.Get("template_name").(string)
	subjectName := d.Get("subject_name").(string)

	resp, err := client.UpdateCertificate(templateName, subjectName)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to update certificate, status: %s", resp.Status)
	}

	return resourceCertificateRead(d, m)
}

func resourceCertificateDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*Client)
	templateName := d.Get("template_name").(string)
	subjectName := d.Get("subject_name").(string)

	resp, err := client.DeleteCertificate(templateName, subjectName)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("failed to delete certificate, status: %s", resp.Status)
	}

	d.SetId("")
	return nil
}
