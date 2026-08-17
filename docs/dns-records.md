# External DNS records

Terraform never modifies the `lax-man.in` zone. Use the authoritative external DNS provider.

The single application domain is `secure.lax-man.in`.

## Phase 1: ACM validation

Run:

```bash
terraform -chdir=terraform/environments/main output -json acm_dns_validation_records
```

Create every returned record exactly:

| Name | Type | Value |
|---|---|---|
| output `.name` | `CNAME` | output `.value` |

Some providers automatically append the zone name; avoid creating `...lax-man.in.lax-man.in`. Keep this validation CNAME permanently so ACM can renew. Wait for:

```bash
aws acm describe-certificate --region us-east-1 --certificate-arn "$(terraform -chdir=terraform/environments/main output -raw acm_certificate_arn)" --query Certificate.Status
```

The result must be `ISSUED` before phase 2.

## Phase 2: application alias

After the second apply:

```bash
terraform -chdir=terraform/environments/main output verified_access_endpoint_domain
terraform -chdir=terraform/environments/main output required_application_dns_record
```

Create:

| Name | Type | Value |
|---|---|---|
| `secure.lax-man.in` | `CNAME` | exact `verified_access_endpoint_domain` output |

Do not point the name at the internal ALB. Verify with `dig +short secure.lax-man.in` or `nslookup` and allow for provider TTL/caching.
