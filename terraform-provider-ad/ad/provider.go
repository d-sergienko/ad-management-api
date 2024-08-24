package ad

import (
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func Provider() *schema.Provider {
	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			"base_url": {
				Type:     schema.TypeString,
				Required: true,
			},
		},
		ConfigureFunc: providerConfigure,
		ResourcesMap: map[string]*schema.Resource{
			"ad_dns_record":  resourceDNSRecord(),
			"ad_certificate": resourceCertificate(),
		},
	}
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
	baseURL := d.Get("base_url").(string)
	client := NewClient(baseURL)
	return client, nil
}
