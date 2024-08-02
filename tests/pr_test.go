package tests

import (
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testprojects"
	"testing"
)

func TestProjectsFullTest(t *testing.T) {
	options := testprojects.TestProjectOptionsDefault(&testprojects.TestProjectsOptions{
		Testing:                t,
		Prefix:                 "rag-stack",
		ParallelDeploy:         true,
		StackConfigurationPath: "basic",
	})

	privateKey, _, kerr := common.GenerateTempGPGKeyPairBase64()
	if kerr != nil {
		t.Fatal(kerr)
	}
	options.StackInputs = map[string]interface{}{
		"resource_group_name":         options.ResourceGroup,
		"ibmcloud_api_key":            options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"],
		"prefix":                      options.Prefix,
		"signing_key":                 privateKey,
		"secret_manager_service_plan": "trial",
	}

	err := options.RunProjectsTest()
	if assert.NoError(t, err) {
		t.Log("TestProjectsFullTest Passed")
	} else {
		t.Error("TestProjectsFullTest Failed")
	}
}
