# Troubleshooting

| Symptom | Checks and action |
|---|---|
| Identity Center wrong Region | Select `us-east-1`; `aws sso-admin list-instances --region us-east-1` must return the organization instance. |
| Standalone/account instance | Use the Organizations management account's organization instance required by this design; do not let Terraform recreate it. |
| Trust provider creation failure | Verify regional IdC, AWS account/delegated admin, Verified Access quotas, and EC2/SSO permissions. |
| Invalid group ID | Copy the immutable UUID, not display name; verify membership in the same identity store. |
| Cedar syntax failure | Check `idc`, quotes, closing `};`, template variables, and test in the Verified Access policy assistant. |
| Approved user denied | Confirm primary email is verified, exact suffix/case used by the directory, group UUID, actual membership, and fresh login session. |
| Certificate pending validation | Compare ACM's record byte-for-byte, remove duplicate zone suffix, allow propagation, and keep it in `us-east-1`. |
| Final DNS incorrect | CNAME `secure.lax-man.in` to the Verified Access endpoint domain—not the ALB or certificate validation value. |
| Endpoint pending/failed | Confirm ACM is `ISSUED`, ALB is internal and healthy, subnets/SGs are in one VPC, and quotas permit creation. |
| ALB target unhealthy | Check target port 8000, `/health`, Docker status through SSM, and ALB-to-app SG rules. |
| EC2 user data failed | SSM into the instance and inspect `/var/log/cloud-init-output.log`; confirm NAT route and repository access. |
| Containers not running | Use `sudo docker ps -a` and `sudo docker logs cloud-notes-backend`; rerun application deployment. |
| SG blocks traffic | Verify references form endpoint SG -> ALB SG:80 -> app SG:8000; never add `0.0.0.0/0` ingress. |
| SSM unavailable | Confirm agent/service, instance profile, NAT/443 egress, DNS, system clock, and `AmazonSSMManagedInstanceCore`. |
| Verified Access logs missing | Confirm logging resource, log group name, deployment role log-delivery permissions, and generate a new request. |
| SNS email absent | Confirm the subscription link and check alarm actions/state. |
| Terraform provider/API error | Run `init -upgrade`, verify provider constraint and region/service quotas, then review AWS error/request ID. |
| GitHub OIDC denied | Check `sts.amazonaws.com` audience, exact legacy/immutable subject prefix, environment name, role ARN, and IAM trust condition. |
| File notes missing | Confirm the Docker volume exists; do not run `docker compose down -v`; restore the volume snapshot/backup. |

Use SSM Session Manager rather than adding SSH. Redact identity headers, Terraform values, and signed context from tickets.
