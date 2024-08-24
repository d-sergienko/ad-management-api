package main

import (
	"github.com/d-sergienko/ad-management-api/terraform-provider-ad/ad"
	"github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: ad.Provider,
	})
}
