provider "ibm" {
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = var.region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && var.region == "ca-mon") ? "vpe" : null
}

provider "elasticsearch" {
  alias                 = "ibm_es"
  username              = module.icd_elasticsearch.service_credentials_object.credentials["elasticsearch_admin"].username
  password              = module.icd_elasticsearch.service_credentials_object.credentials["elasticsearch_admin"].password
  url                   = "https://${module.icd_elasticsearch.service_credentials_object.hostname}:${module.icd_elasticsearch.service_credentials_object.port}"
  cacert_file           = base64decode(module.icd_elasticsearch.service_credentials_object.certificate)
  elasticsearch_version = "8.12"

  # Below is required to avoid HEAD healthcheck failed error. Reference to similar issue and suggestion - https://github.com/phillbaker/terraform-provider-elasticsearch/issues/352
  healthcheck           = false
}

provider "restapi" {
  uri                  = "https:"
  write_returns_object = true
  debug                = true
  headers = {
    Authorization = data.ibm_iam_auth_token.restapi.iam_access_token
    Content-Type  = "application/json"
  }
}
