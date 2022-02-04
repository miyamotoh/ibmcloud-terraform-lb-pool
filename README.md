# ibmcloud-terraform-lb-pool
To aid debugging the TF re-apply issue on ibm_is_lb_pool_member resource

1. Clone this repo
1. `cd` to it
1. edit the `locals` block in `main.tf` with your VPC setup
1. `terraform init`
1. `terraform apply -var api_key=$IBMCLOUD_API_KEY`
1. see 7 resources successfully created
1. optionally check that the pool has 4 members
1. `terraform apply -var api_key=$IBMCLOUD_API_KEY -var expose_bootstrap=false`
1. see the error
