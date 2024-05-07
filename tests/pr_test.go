package tests

import (
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testprojects"
	"testing"
)

func TestProjectsFullTest(t *testing.T) {

	options := testprojects.TestProjectOptionsDefault(&testprojects.TestProjectsOptions{
		Testing:       t,
		Prefix:        "rag-stack",
		ResourceGroup: "",
		StackConfigurationOrder: []string{
			"1 - Account Infrastructure Base",
			"2a - Security Service - Key Management",
			"2b - Security Service - Secret Manager",
			"2c - Security Service - Security Compliance Center",
			"3 - Observability - Logging Monitoring Activity Tracker",
			"4 - WatsonX SaaS services",
			"5 - RAG Sample App - Code Engine Toolchain Config",
			"6 - Sample RAG app configuration",
		},
	})

	options.StackInputs = map[string]interface{}{
		"resource_group_name": options.ResourceGroup,
		"ibmcloud_api_key":    options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"],
		"prefix":              options.Prefix,
	}

	err := options.RunProjectsTest()
	if assert.NoError(t, err) {
		t.Log("TestProjectsFullTest Passed")
	} else {
		t.Error("TestProjectsFullTest Failed")
	}
}
